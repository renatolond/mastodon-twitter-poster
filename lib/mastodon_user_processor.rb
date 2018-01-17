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
    rescue HTTP::ConnectionError
      Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
      stats.increment('domain.offline')
    rescue HTTP::Error => ex
      if ex.message == 'Unknown MIME type: text/html'
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
        stats.increment('domain.offline')
      else
        Rails.logger.error { "Could not process user #{user.twitter.uid}. -- #{ex} -- Bailing out" }
        stats.increment("user.processing_error")
      end
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
      rescue HTTP::ConnectionError
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
        stats.increment('domain.offline')
        break
      rescue HTTP::Error => ex
        if ex.message == 'Unknown MIME type: text/html'
          Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
          stats.increment('domain.offline')
          break
        else
          Rails.logger.error { "Could not process user #{user.mastodon.uid}, toot #{t.id}. -- #{ex} -- Bailing out" }
          stats.increment("toot.processing_error")
          break
        end
      rescue Twitter::Error::Forbidden => ex
        Rails.logger.error { "Bad authentication for user #{user.mastodon.uid} while processing toot #{t.id}. #{ex.to_json}." }
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
      unless twitter_status_exist?(self.replied_status.tweet_id)
        Rails.logger.debug('Ignoring masto reply to self because the one we were replying to doesn\'t exist anymore')
        MastodonUserProcessor::stats.increment("toot.reply_to_self.skipped")
        return
      end
      if should_post
        post_toot
      else
        MastodonUserProcessor::stats.increment("toot.reply_to_self.visibility.skipped")
        Rails.logger.debug('Ignoring normal toot because of visibility configuration')
      end
    end
  end

  def twitter_status_exist?(tweet_id)
    begin
      user.twitter_client.status(tweet_id)
    rescue Twitter::Error::NotFound
      return false
    end
    true
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
    Status.create(mastodon_client: user.mastodon.mastodon_client, masto_id: toot.id, tweet_id: status.id)
    MastodonUserProcessor::stats.increment('toot.posted_to_twitter')
    MastodonUserProcessor::stats.timing('toot.average_time_to_post', ((Time.now-DateTime.strptime(toot.created_at, '%FT%T.%L%z'))*1000).round(5))
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn { "Duplicated tweet when crossposting #{user.mastodon.uid}, toot #{toot.id}. -- #{status.id} -- Skipping" }
  end

  def treat_media_attachments(medias)
    media_ids = []
    opts = {}
    media_type = nil
    medias.each do |media|
      url = get_url_for_media(media)

      if ['image/gif', 'video/mp4'].include?(media_type)
        self.force_toot_url = true
        next
      end

      file = Tempfile.new(['media', File.extname(url)], "#{Rails.root}/tmp")
      file.binmode
      begin
        file.write HTTParty.get(media.url).body
        file.rewind
        file_type = detect_media_type(file)
        media_type = file_type if media_type.nil?

        if media_type != file_type
          self.force_toot_url = true
          next
        end

        media_ids << upload_media(media, file, file_type)
      ensure
        file.close
        file.unlink
      end
    end

    opts[:media_ids] = media_ids.join(',') unless media_ids.empty?
    opts
  end

  def get_url_for_media(media)
    url = URI.parse(media.url)
    url.query = nil
    url.to_s
  end

  def upload_media(media, file, file_type)
    media_id = nil
      options = detect_twitter_filetype(file_type)
      media_id = user.twitter_client.upload(file, options).to_s
      user.twitter_client.create_metadata(media_id, alt_text: {text: media.to_h['description']}) unless media.to_h['description'].blank?
    return media_id
  end

  def self.file_magic
    @@fm ||= FileMagic.mime
  end

  def detect_twitter_filetype(file_type)
    options = {}
    if file_type == 'video/mp4'
      options = {media_type: 'video/mp4', media_category: 'tweet_video'}
    else
      options = {media_type: file_type, media_category: 'tweet_image'}
    end
    options
  end

  def detect_media_type(file)
    self.class.file_magic.file(file.path, true)
  end

  private
  def force_toot_url=(force)
    @force_toot_url = force
  end

  def force_toot_url
    @force_toot_url ||= false
  end
end
