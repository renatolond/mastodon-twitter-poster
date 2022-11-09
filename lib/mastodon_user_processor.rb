# frozen_string_literal: true

require "mastodon_ext"
require "uri"

class MastodonUserProcessor
  def self.stats
    @@stats ||= Stats.new
  end

  class TootError < StandardError
    def initialize(error)
      @error = error
    end
    attr_reader :error
  end

  def self.process_user(user)
    get_last_toots_for_user(user) if user.posting_from_mastodon
  rescue HTTP::ConnectionError, Oj::ParseError => ex
    Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
    stats.increment("domain.offline")
    raise ex
  rescue OpenSSL::SSL::SSLError => ex
    Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} has SSL issues" }
    stats.increment("domain.ssl_error")
    raise ex
  rescue HTTP::Error => ex
    if ex.message == "Unknown MIME type: text/html"
      Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
      stats.increment("domain.offline")
      raise ex
    else
      Rails.logger.error { "Issue connecting to user #{user.mastodon.uid}. -- #{ex} -- Bailing out" }
      stats.increment("user.http_error")
      raise ex
    end
  rescue TootError => ex
    raise ex.error
  rescue => ex
    Rails.logger.error { "Could not process user #{user.mastodon.uid}. -- #{ex} -- Bailing out" }
    stats.increment("user.processing_error")
    raise ex
  ensure
    user.mastodon_last_check = Time.now
    user.twitter_last_check = Time.now unless user.posting_from_twitter
    user.save
  end

  def self.statuses_options(user)
    opts = {}
    opts[:since_id] = user.last_toot unless user.last_toot.nil?
    opts
  end

  TWITTER_CANNOT_PERFORM_WRITE_ACTIONS = 261

  def self.stoplight_wrap_request(domain, &)
    if domain.present?
      Stoplight("source:#{domain}", &)
        .with_threshold(3)
        .with_cool_off_time(5.minutes.seconds)
        .with_error_handler { |error, handle| error.is_a?(HTTP::Error) || error.is_a?(OpenSSL::SSL::SSLError) ? handle.call(error) : raise(error) }
        .run
    else
      yield
    end
  end

  def self.get_last_toots_for_user(user)
    return unless user.mastodon && user.twitter

    opts = statuses_options(user)

    new_toots = stoplight_wrap_request(user.mastodon_domain) do
      user.mastodon_client.statuses(user.mastodon_id, opts)
    end

    last_successful_toot = nil
    new_toots.to_a.reverse_each do |t|
      begin
        MastodonUserProcessor.new(t, user).process_toot
        last_successful_toot = t
      rescue HTTP::ConnectionError, Oj::ParseError => ex
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
        stats.increment("domain.offline")
        raise TootError.new(ex)
      rescue OpenSSL::SSL::SSLError => ex
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} has SSL issues" }
        stats.increment("domain.ssl_error")
        raise TootError.new(ex)
      rescue HTTP::Error => ex
        if ex.message == "Unknown MIME type: text/html"
          Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
          stats.increment("domain.offline")
          raise TootError.new(ex)
        else
          Rails.logger.error { "Issue connecting to post #{user.mastodon.uid}, toot #{t.id}. -- #{ex} -- Bailing out" }
          stats.increment("toot.http_error")
          raise TootError.new(ex)
        end
      rescue Twitter::Error::Forbidden => ex
        if ex.code == TWITTER_CANNOT_PERFORM_WRITE_ACTIONS
          Rails.logger.error { "Forbidden to write to twitter while processing #{user.mastodon.uid} while processing toot #{t.id}." }
          stats.increment("twitter.write_action_forbidden")
        else
          Rails.logger.error { "Bad authentication for user #{user.mastodon.uid} while processing toot #{t.id}. #{ex.to_json}." }
          stats.increment("twitter.bad_auth")
          raise TootError.new(ex)
        end
      rescue Twitter::Error::BadRequest => ex
        Rails.logger.error { "Could not process user #{user.mastodon.uid}, toot #{t.id}. -- #{ex} (#{ex.code}) -- Bailing out" }
        stats.increment("toot.processing_error")
        raise TootError.new(ex)
      rescue => ex
        Rails.logger.error { "Could not process user #{user.mastodon.uid}, toot #{t.id}. -- #{ex} -- Bailing out" }
        stats.increment("toot.processing_error")
        raise TootError.new(ex)
      end
    end
  ensure
    user.last_toot = last_successful_toot.id unless last_successful_toot.nil?
    user.mastodon_last_check = Time.now
    user.save
  end

  def initialize(toot, user)
    @toot = toot
    @user = user
  end

  attr_reader :toot

  attr_reader :user

  attr_accessor :replied_status

  def text_filter
    @text_filter ||= TextFilter.new(@user)
  end

  def posted_by_crossposter
    application = toot.application || {}
    website = application["website"] || ""
    name = application["name"] || ""
    return true unless website["https://crossposter.masto.donte.com.br"].nil? &&
      name["Mastodon Twitter Crossposter"].nil? &&
      website[Rails.configuration.x.domain].nil? &&
      name[Rails.configuration.x.application_name].nil? &&
      website["https://moa.party"].nil? &&
      Status.where(masto_id: toot.id, mastodon_client: user.mastodon.mastodon_client_id).count == 0
    false
  end

  def process_toot
    if posted_by_crossposter
      Rails.logger.debug("Ignoring toot, was posted by the crossposter")
      MastodonUserProcessor.stats.increment("toot.posted_by_crossposter.skipped")
      return
    end

    if text_filter.should_filter_coming_from_mastodon?(toot.text_content, toot.spoiler_text)
      Rails.logger.debug("Ignoring toot, does not obey word list")
      MastodonUserProcessor.stats.increment("toot.word_list.skipped")
      return
    end

    if toot.text_content.gsub(/[[:space:]]+/, "").empty? && toot.spoiler_text.gsub(/[[:space:]]+/, "").empty?
      Rails.logger.debug("Ignoring toot, was empty")
      MastodonUserProcessor.stats.increment("toot.empty.skipped")
      return
    end

    if toot.is_direct?
      Rails.logger.debug("Ignoring direct toot. We do not treat them")
      MastodonUserProcessor.stats.increment("toot.direct.skipped")
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
      Rails.logger.debug("Ignoring masto boost because user choose so")
      MastodonUserProcessor.stats.increment("toot.boost.skipped")
      nil
    elsif user.masto_boost_post_as_link?
      boost_as_link
    end
  end

  def boost_as_link
    content = "Boosted: #{toot.reblog.url}"
    if should_post
      tweet(content)
    else
      Rails.logger.debug("Ignoring boost because of visibility configuration")
      MastodonUserProcessor.stats.increment("toot.boost.visibility.skipped")
    end
  end

  def process_reply
    if user.masto_reply_do_not_post?
      Rails.logger.debug("Ignoring masto reply because user choose so")
      MastodonUserProcessor.stats.increment("toot.reply.skipped")
      return
    end

    if user.masto_reply_post_self? && toot.in_reply_to_account_id != toot.account.id
      Rails.logger.debug("Ignoring masto reply because reply is not to self")
      MastodonUserProcessor.stats.increment("toot.reply.skipped")
      return
    end

    self.replied_status = Status.find_by(mastodon_client: user.mastodon.mastodon_client, masto_id: toot.in_reply_to_id)
    if self.replied_status.nil?
      Rails.logger.debug("Ignoring masto reply to self because we haven't crossposted the original")
      MastodonUserProcessor.stats.increment("toot.reply_to_self.skipped")
    else
      unless twitter_status_exist?(self.replied_status.tweet_id)
        Rails.logger.debug("Ignoring masto reply to self because the one we were replying to doesn't exist anymore")
        MastodonUserProcessor.stats.increment("toot.reply_to_self.skipped")
        return
      end
      if should_post
        post_toot
      else
        MastodonUserProcessor.stats.increment("toot.reply_to_self.visibility.skipped")
        Rails.logger.debug("Ignoring normal toot because of visibility configuration")
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
      Rails.logger.debug("Ignoring masto mention because user choose so")
      MastodonUserProcessor.stats.increment("toot.mention.skipped")
      nil
    end
  end

  TWITTER_MAX_CHARS = 280

  def process_normal_toot
    Rails.logger.debug { "Processing toot: #{toot.text_content}" }
    if should_post
      post_toot
    else
      MastodonUserProcessor.stats.increment("toot.normal.visibility.skipped")
      Rails.logger.debug("Ignoring normal toot because of visibility configuration")
    end
  end

  def should_add_image_count?
    toot.sensitive? && toot.spoiler_text.blank? && toot.media_attachments.count > 0
  end

  def post_toot
    tweet_content = TootTransformer.new(TWITTER_MAX_CHARS).transform(toot_content_to_post, toot.url, user.mastodon_domain, user.mastodon.mastodon_client.domain)
    if should_add_image_count?
      self.force_toot_url = true
    end

    opts = {}
    opts.merge!(treat_media_attachments(toot.media_attachments)) unless toot.sensitive?
    if self.replied_status
      opts[:in_reply_to_status_id] = self.replied_status.tweet_id
      opts[:auto_populate_reply_metadata] = true
    end
    if force_toot_url
      tweet_content = handle_force_url(tweet_content)
    end
    tweet(tweet_content, opts)
  end

  def handle_force_url(content)
    return content if content.include?(toot.url)
    TootTransformer.new(TWITTER_MAX_CHARS).transform(toot_content_to_post + "… #{toot.url}", toot.url, user.mastodon_domain, user.mastodon.mastodon_client.domain)
  end

  def toot_content_to_post
    tweet = toot.text_content
    tweet_includes_content = true

    if toot.sensitive? && toot.spoiler_text.present?
      if user.masto_cw_options == "cw_and_content"
        tweet = "CW: #{toot.spoiler_text}\n\n#{toot.text_content}"
      elsif user.masto_cw_options == "cw_only"
        tweet = "CW: #{toot.spoiler_text}"
        tweet_includes_content = false
      elsif user.masto_cw_options == "content_only"
        tweet = toot.text_content
      else
        raise "invalid masto_cw_options"
      end
    end

    @force_toot_url = true unless tweet_includes_content

    if tweet_includes_content && should_add_image_count?
      tweet = "#{tweet}… #{toot.media_attachments.count} 🖼️"
    end

    tweet
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

  def tweet(content, opts = {})
    Rails.logger.debug { "Posting to twitter: #{content}" }
    return if content.gsub(toot.url, "").gsub(/https:\/\/[^\s\/]+\/[@＠][^\s\/]+(?:\/|\w)/, "").gsub("@ ", "").gsub(/[@＠]\Z/, "").match?(/(?:^|[^A-Za-z0-9])[@＠]/)
    status = user.twitter_client.update(content, opts)
    Status.create(mastodon_client: user.mastodon.mastodon_client, masto_id: toot.id, tweet_id: status.id)
    MastodonUserProcessor.stats.increment("toot.posted_to_twitter")
    MastodonUserProcessor.stats.timing("toot.average_time_to_post", ((Time.now - DateTime.strptime(toot.created_at, "%FT%T.%L%z")) * 1000).round(5))
  rescue ActiveRecord::RecordNotUnique
    Rails.logger.warn { "Duplicated tweet when crossposting #{user.mastodon.uid}, toot #{toot.id}. -- #{status.id} -- Skipping" }
  end

  TWITTER_DURATION_TOO_SHORT = 324

  def treat_media_attachments(medias)
    media_ids = []
    opts = {}
    media_type = nil
    medias.each do |media|
      url = get_url_for_media(media)

      if ["image/gif", "video/mp4"].include?(media_type) || (media.attributes.dig("meta", "fps").present? && media.attributes.dig("meta", "fps") > 60)
        self.force_toot_url = true
        next
      end

      file = Tempfile.new(["media", File.extname(url)], "#{Rails.root}/tmp")
      file.binmode
      begin
        file.write HTTParty.get(media.url).body
        file.rewind
        file_type = detect_media_type(file)
        if file_type == "video/webm" || file_type == "application/octet-stream"
          self.force_toot_url = true
          next
        end

        media_type = file_type if media_type.nil?

        if media_type != file_type
          self.force_toot_url = true
          next
        end

        media_ids << upload_media(media, file, file_type)
      rescue Twitter::Error::ClientError
        self.force_toot_url = true
        next
      rescue Twitter::Error::BadRequest => ex
        if ex.code == TWITTER_DURATION_TOO_SHORT
          next
        else
          raise ex
        end
      ensure
        file.close
        file.unlink
      end
    end

    opts[:media_ids] = media_ids.join(",") unless media_ids.empty?
    opts
  end

  def get_url_for_media(media)
    url = URI.parse(media.url)
    url.query = nil
    url.to_s
  end

  MEDIA_DESCRIPTION_CHAR_LIMIT = 1_000 # From https://help.twitter.com/en/using-twitter/write-image-descriptions
  def upload_media(media, file, file_type)
    media_id = nil
    options = detect_twitter_filetype(file_type)
    media_id = user.twitter_client.upload(file, options).to_s
    unless media.to_h["description"].blank?
      alt_text = media.to_h["description"].truncate(MEDIA_DESCRIPTION_CHAR_LIMIT, separator: /[ \n]/, omission: "…")
      user.twitter_client.create_metadata(media_id, alt_text: { text: alt_text })
    end
    media_id
  end

  def self.file_magic
    @@fm ||= FileMagic.mime
  end

  def detect_twitter_filetype(file_type)
    options = {}
    if ["video/mp4", "video/webm"].include?(file_type)
      options = { media_type: file_type, media_category: "tweet_video" }
    else
      options = { media_type: file_type, media_category: "tweet_image" }
    end
    options
  end

  def detect_media_type(file)
    self.class.file_magic.file(file.path, true)
  end

  private
    attr_writer :force_toot_url

    def force_toot_url
      @force_toot_url ||= false
    end
end
