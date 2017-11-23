require 'stats'
require 'mastodon_ext'
require 'toot_transformer'
require 'uri'

class MastodonUserProcessor
  def self.stats
    @@stats ||= Stats.new
  end

  def self.process_user(user)
    begin
      get_last_toots_for_user(user) if user.posting_from_mastodon
    rescue StandardError => ex
      Rails.logger.error { "Could not process user #{user.mastodon.uid}. -- #{ex} -- Bailing out" }
      stats.increment("user.processing_error")
    ensure
      user.mastodon_last_check = Time.now
      user.twitter_last_check = Time.now unless user.posting_from_twitter
      user.save
    end
  end

  def self.statuses_options(user)
    opts = {}
    opts[:since_id] = user.last_toot unless user.last_toot.nil?
    opts
  end

  def self.get_last_toots_for_user(user)
    return unless user.mastodon && user.twitter

    opts = statuses_options(user)

    new_toots = user.mastodon_client.statuses(user.mastodon_id, opts)
    last_sucessful_toot = nil
    new_toots.to_a.reverse.each do |t|
      begin
        MastodonUserProcessor.new(t, user).process_toot
        last_sucessful_toot = t
      rescue Twitter::Error::Forbidden => ex
        Rails.logger.error { "Bad authentication for user #{user.mastodon.uid}." }
        stats.increment("twitter.bad_auth")
        break
      rescue => ex
        Rails.logger.error { "Could not process user #{user.mastodon.uid}, toot #{t.id}. -- #{ex} -- Bailing out" }
        stats.increment("toot.processing_error")
        break
      end
    end

    user.last_toot = last_sucessful_toot.id unless last_sucessful_toot.nil?
    user.mastodon_last_check = Time.now
    user.save
  end

  def initialize(toot, user)
    @toot = toot
    @user = user
  end

  def toot
    @toot
  end

  def user
    @user
  end

  def replied_status=(replied_status)
    @replied_status=replied_status
  end

  def replied_status
    @replied_status
  end

  def posted_by_crossposter
    return true unless (toot.application.nil? || toot.application['website'] != 'https://crossposter.masto.donte.com.br') &&
      Status.where(masto_id: toot.id, mastodon_client: user.mastodon.mastodon_client_id).count == 0
    false
  end

  def process_toot
    if posted_by_crossposter
      Rails.logger.debug('Ignoring toot, was posted by the crossposter')
      MastodonUserProcessor::stats.increment('toot.posted_by_crossposter.skipped')
      return
    end

    if toot.is_direct?
      Rails.logger.debug('Ignoring direct toot. We do not treat them')
      MastodonUserProcessor::stats.increment("toot.direct.skipped")
      # no sense in treating direct toots. could become an option in future, maybe.
      return
    elsif toot.is_reblog?
      process_boost
    elsif toot.is_reply?
      process_reply
    elsif toot.is_mention?
      process_mention
    else
      process_normal_toot
    end
  end

  def process_boost
    if user.masto_boost_do_not_post?
      Rails.logger.debug('Ignoring masto boost because user choose so')
      MastodonUserProcessor::stats.increment("toot.boost.skipped")
      return
    elsif user.masto_boost_post_as_link?
      boost_as_link
    end
  end

  def boost_as_link
    content = "Boosted: #{toot.url}"
    if should_post
      tweet(content)
    else
      Rails.logger.debug('Ignoring boost because of visibility configuration')
      MastodonUserProcessor::stats.increment("toot.boost.visibility.skipped")
    end
  end

  def process_reply
    if user.masto_reply_do_not_post?
      Rails.logger.debug('Ignoring masto reply because user choose so')
      MastodonUserProcessor::stats.increment("toot.reply.skipped")
      return
    end

    if user.masto_reply_post_self? && toot.in_reply_to_account_id != toot.account.id
      Rails.logger.debug('Ignoring masto reply because reply is not to self')
      MastodonUserProcessor::stats.increment("toot.reply.skipped")
      return
    end

    self.replied_status = Status.find_by(mastodon_client: user.mastodon.mastodon_client, masto_id: toot.in_reply_to_id)
    if self.replied_status.nil?
      Rails.logger.debug('Ignoring masto reply to self because we haven\'t crossposted the original')
      MastodonUserProcessor::stats.increment("toot.reply_to_self.skipped")
    else
      if should_post
        post_toot
      else
        MastodonUserProcessor::stats.increment("toot.reply_to_self.visibility.skipped")
        Rails.logger.debug('Ignoring normal toot because of visibility configuration')
      end
    end
  end

  def process_mention
    if user.masto_mention_do_not_post?
      Rails.logger.debug('Ignoring masto mention because user choose so')
      MastodonUserProcessor::stats.increment("toot.mention.skipped")
      return
    end
  end

  TWITTER_MAX_CHARS = 280

  def process_normal_toot
    Rails.logger.debug{ "Processing toot: #{toot.text_content}" }
    if should_post
      post_toot
    else
      MastodonUserProcessor::stats.increment("toot.normal.visibility.skipped")
      Rails.logger.debug('Ignoring normal toot because of visibility configuration')
    end
  end

  def post_toot
    tweet_content = TootTransformer.new(TWITTER_MAX_CHARS).transform(toot_content_to_post, toot.url, user.mastodon_domain, user.masto_fix_cross_mention)
    opts = {}
    opts.merge!(treat_media_attachments(toot.media_attachments)) unless toot.sensitive?
    opts.merge!(in_reply_to_status_id: self.replied_status.tweet_id, auto_populate_reply_metadata: true) if self.replied_status
    if force_toot_url
      tweet_content = handle_force_url(tweet_content)
    end
    tweet(tweet_content, opts)
  end

  def handle_force_url(content)
    return content if content.include?(toot.url)
    TootTransformer.new(TWITTER_MAX_CHARS).transform(content + "… #{toot.url}", toot.url, user.mastodon_domain, nil)
  end

  def toot_content_to_post
    if toot.sensitive?
      "CW: #{toot.spoiler_text} … #{toot.url}"
    else
      toot.text_content
    end
  end

  def should_post
    if toot.is_public? ||
        (toot.is_unlisted? && user.masto_should_post_unlisted?) ||
        (toot.is_private? && user.masto_should_post_private?)
      true
    else
      false
    end
  end

  TWITTER_TOO_LONG_ERROR_CODE = 186
  TWITTER_OLD_MAX_CHARS = 140

  def tweet(content, opts = {})
    Rails.logger.debug { "Posting to twitter: #{content}" }
    begin
    status = user.twitter_client.update(content, opts)
    rescue Twitter::Error::Forbidden => ex
      raise ex unless ex.code == TWITTER_TOO_LONG_ERROR_CODE
      status = user.twitter_client.update(TootTransformer.new(TWITTER_OLD_MAX_CHARS).transform(content, toot.url, user.mastodon_domain, user.masto_fix_cross_mention), opts)
    end
    MastodonUserProcessor::stats.increment('toot.posted_to_twitter')
    Status.create(mastodon_client: user.mastodon.mastodon_client, masto_id: toot.id, tweet_id: status.id)
  end

  def treat_media_attachments(medias)
    media_ids = []
    opts = {}
    media_type = nil
    medias.each do |media|
      url = URI.parse(media.url)
      url.query = nil
      url = url.to_s

      if media_type.nil?
        media_type = detect_media_type(url)
      elsif media_type != detect_media_type(url) || [:gif, :mp4].include?(media_type)
        self.force_toot_url = true
        next
      end

      media_ids << upload_media(media, url)
    end

    opts[:media_ids] = media_ids.join(',') unless media_ids.empty?
    opts
  end

  def upload_media(media, url)
    file = Tempfile.new(['media', File.extname(url)], "#{Rails.root}/tmp")
    file.binmode
    media_id = nil
    begin
      file.write HTTParty.get(media.url).body
      file.rewind
      options = detect_twitter_filetype(url)
      media_id = user.twitter_client.upload(file, options).to_s
      user.twitter_client.create_metadata(media_id, alt_text: {text: media.to_h['description']}) unless media.to_h['description'].nil?
    ensure
      file.close
      file.unlink
    end
    return media_id
  end

  def detect_twitter_filetype(url)
    options = {}
    options = {media_type: 'video/mp4', media_category: 'tweet_video'} if File.extname(url) == '.mp4'
    options = {media_type: 'image/png', media_category: 'tweet_image'} if File.extname(url) == '.png'
    options = {media_type: 'image/jpeg', media_category: 'tweet_image'} if File.extname(url) =~ /\.jpe?g$/
    options = {media_type: 'image/gif', media_category: 'tweet_image'} if File.extname(url) == '.gif'
    options
  end

  def detect_media_type(url)
    return :mp4 if File.extname(url) == '.mp4'
    return :gif if File.extname(url) == '.gif'
    return :image if File.extname(url) == '.png' || File.extname(url) =~ /\.jpe?g$/
  end

  private
  def force_toot_url=(force)
    @force_toot_url = force
  end

  def force_toot_url
    @force_toot_url ||= false
  end
end
