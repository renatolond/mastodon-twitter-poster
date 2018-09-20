# frozen_string_literal: true

require 'stats'
require 'tweet_transformer'

class TwitterUserProcessor
  def self.html_entities
    @@html_entities ||= HTMLEntities.new
  end

  def self.stats
    @@stats ||= Stats.new
  end

  class TweetError < StandardError
    def initialize(error)
      @error = error
    end
    def error
      @error
    end
  end

  def self.process_user(user)
    begin
      get_last_tweets_for_user(user) if user.posting_from_twitter
    rescue TweetError => ex
      raise ex.error
    rescue StandardError => ex
      Rails.logger.error { "Could not process user #{user.twitter.uid}. -- #{ex} -- Bailing out" }
      stats.increment("user.processing_error")
      raise ex
    ensure
      user.twitter_last_check = Time.now
      user.mastodon_last_check = Time.now unless user.posting_from_mastodon
      user.save
    end
  end

  def self.user_timeline_options(user)
    opts = {}
    opts[:since_id] = user.last_tweet unless user.last_tweet.nil?
    opts
  end

  def self.get_last_tweets_for_user(user)
    return unless user.mastodon && user.twitter

    new_tweets = user.twitter_client.user_timeline(user_timeline_options(user).merge({tweet_mode: 'extended', include_ext_alt_text: true}))
    last_successful_tweet = nil
    new_tweets.reverse.each do |t|
      begin
        TwitterUserProcessor.new(t, user).process_tweet
        last_successful_tweet = t
      rescue HTTP::ConnectionError => ex
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
        stats.increment('domain.offline')
        raise TweetError.new(ex)
      rescue OpenSSL::SSL::SSLError => ex
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} has SSL issues" }
        stats.increment('domain.ssl_error')
        raise TweetError.new(ex)
      rescue HTTP::Error => ex
        if ex.message == 'Unknown MIME type: text/html'
          Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
          stats.increment('domain.offline')
          raise TweetError.new(ex)
        else
          Rails.logger.error { "Issue connecting to post #{user.twitter.uid}, tweet #{t.id}. (#{user.mastodon.mastodon_client.domain})  -- #{ex} -- Bailing out" }
          stats.increment("tweet.http_error")
          raise TweetError.new(ex)
        end
      rescue StandardError => ex
        Rails.logger.error { "Could not process user #{user.twitter.uid}, tweet #{t.id}. -- #{ex} -- Bailing out" }
        stats.increment("tweet.processing_error")
        raise TweetError.new(ex)
      end
    end

  ensure
    user.last_tweet = last_successful_tweet.id unless last_successful_tweet.nil?
    user.save
  end

  def initialize(tweet, user)
    @tweet = tweet
    @user = user
  end

  def tweet
    @tweet
  end

  def user
    @user
  end

  def replied_status_id=(replied_status_id)
    @replied_status_id=replied_status_id
  end

  def replied_status_id
    @replied_status_id
  end

  def posted_by_crossposter
    return true unless tweet.source['https://crossposter.masto.donte.com.br'].nil? &&
    tweet.source['https://github.com/renatolond/mastodon-twitter-poster'].nil? &&
    tweet.source[Rails.configuration.x.domain].nil? &&
    tweet.source['https://moa.party'].nil? &&
    Status.find_by_tweet_id(tweet.id) == nil
    false
  end

  def process_tweet
    if(posted_by_crossposter)
      Rails.logger.debug('Ignoring tweet, was posted by the crossposter')
      self.class.stats.increment('tweet.posted_by_crossposter.skipped')
      return
    end

    if(tweet.retweet? || tweet.full_text[0..3] == 'RT @')
      process_retweet
    elsif tweet.reply?
      process_reply
    elsif tweet.quoted_status?
      process_quote
    else
      process_normal_tweet
    end
  end

  def process_retweet
    @type = :retweet
    if user.retweet_do_not_post?
      Rails.logger.debug('Ignoring retweet because user chose so')
      self.class.stats.increment("tweet.retweet.skipped")
    elsif user.retweet_post_as_old_rt? || user.retweet_post_as_old_rt_with_link?
      retweet = tweet.retweeted_status
      text, cw = convert_twitter_text(tweet.full_text.dup, tweet.urls + retweet.urls, (tweet.media + retweet.media).uniq)
      text << "\n\n🐦🔗: #{retweet.url}" if user.retweet_post_as_old_rt_with_link?
      save_status = true
      toot(text, @medias[0..3], tweet.possibly_sensitive? || user.twitter_content_warning.present? || cw.present?, save_status, cw || user.twitter_content_warning)
    end
  end

  def process_quote
    @type = :quote
    if user.quote_do_not_post?
      Rails.logger.debug('Ignoring quote because user chose so')
      self.class.stats.increment("tweet.quote.skipped")
    elsif user.quote_post_as_old_rt? || user.quote_post_as_old_rt_with_link?
      process_quote_as_old_rt
    end
  end

  def quote_short_url()
    tweet.urls.find { |u| u.expanded_url.to_s.downcase == tweet.quoted_status_permalink.expanded.to_s.downcase }.url
  end

  def process_quote_as_old_rt
      quote = tweet.quoted_status
      full_text = "#{tweet.full_text.gsub(" #{quote_short_url}", '')}\nRT @#{quote.user.screen_name} #{quote.full_text}"
      text, cw = convert_twitter_text(full_text, tweet.urls + quote.urls, (tweet.media + quote.media).uniq)
      text << "\n\n🐦🔗: #{quote.url}" if user.quote_post_as_old_rt_with_link?
      if text.length + (user.twitter_content_warning&.length||0) <= 500
        save_status = true
        toot(text, @medias[0..3], tweet.possibly_sensitive? || user.twitter_content_warning.present? || cw.present?, save_status, cw || user.twitter_content_warning)
      else
        text, _ = convert_twitter_text("RT @#{quote.user.screen_name} #{quote.full_text}", quote.urls, quote.media)
        text << "\n\n🐦🔗: #{quote.url}" if user.quote_post_as_old_rt_with_link?
        save_status = false
        @idempotency_key = "#{user.mastodon.uid.split('@')[0]}-#{quote.id}"
        quote_id = toot(text, @medias, quote.possibly_sensitive? || user.twitter_content_warning.present? || cw.present?, save_status, cw || user.twitter_content_warning)
        text, cw = convert_twitter_text(tweet.full_text.gsub(" #{quote_short_url}", ''), tweet.urls, tweet.media)
        save_status = true
        self.replied_status_id = quote_id
        toot(text, @medias[0..3], tweet.possibly_sensitive? || user.twitter_content_warning.present? || cw.present?, save_status, cw || user.twitter_content_warning)
      end
  end

  def process_reply
    if user.twitter_reply_do_not_post?
      Rails.logger.debug('Ignoring reply, because user choose so')
      self.class.stats.increment("tweet.reply.skipped")
      return
    end

    if user.twitter_reply_post_self? && tweet.in_reply_to_user_id != tweet.user.id
      Rails.logger.debug('Ignoring reply, because reply is not to self')
      self.class.stats.increment("tweet.reply.skipped")
      return
    end

    replied_status = Status.find_by(mastodon_client: user.mastodon.mastodon_client, tweet_id: tweet.in_reply_to_status_id)
    if replied_status.nil?
      Rails.logger.debug('Ignoring twitter reply to self because we haven\'t crossposted the original')
      self.class.stats.increment("tweet.reply_to_self.skipped")
    else
      self.replied_status_id = replied_status.masto_id
      unless mastodon_status_exist?(replied_status_id)
        Rails.logger.debug('Ignoring twitter reply to self because the one we were replying to doesn\'t exist anymore')
        self.class.stats.increment("tweet.reply_to_self.skipped")
        return
      end
      @type = :original
      text, cw = convert_twitter_text(tweet.full_text.dup, tweet.urls, tweet.media)
      save_status = true
      toot(text, @medias[0..3], tweet.possibly_sensitive? || user.twitter_content_warning.present? || cw.present?, save_status, cw || user.twitter_content_warning)
    end
  end

  def mastodon_status_exist?(status_id)
    begin
      user.mastodon_client.status(status_id)
    rescue KeyError
      return false
    end
    true
  end

  def convert_twitter_text(text, urls, media)
    text = TweetTransformer::replace_links(text, urls)
    text = TweetTransformer::replace_mentions(text)
    text, cw = TweetTransformer::detect_cw(text)
    text = find_media(media, text)
    text = self.class.html_entities.decode(text)
    text = '🖼️' if text.empty?
    [text, cw]
  end

  def process_normal_tweet
    @type = :original if @type.blank?
    text, cw = convert_twitter_text(tweet.full_text.dup, tweet.urls, tweet.media)
    save_status = true
    toot(text, @medias[0..3], tweet.possibly_sensitive? || user.twitter_content_warning.present? || cw.present?, save_status, cw || user.twitter_content_warning)
  end

  class UnknownMediaException < StandardError
    def initialize(exception)
      @exception = exception
    end

    def inner_exception
      @exception
    end
  end

  def find_media(tweet_medias, text)
    @medias = []
    media_type = nil
    tweet_medias.each do |media|
      media_type = media.type if media_type.nil?
      if media_type != media.type
        text = text.gsub(media.url, media.expanded_url.to_s).strip
        next
      end
      media_url = media_url_for(media)
      if media_url.nil?
        text = text.gsub(media.url, media.expanded_url.to_s).strip
        next
      end
      new_text = text.gsub(media.url, '').strip
      begin
        file = Tempfile.new(['media', File.extname(clean_url(media_url))], "#{Rails.root}/tmp")
        file.binmode
        file.write HTTParty.get(media_url).body
        file.rewind
        @medias << upload_media(media, file)
        text = new_text
      rescue UnknownMediaException => ex
        Rails.logger.error("Caught exception #{ex.inner_exception} when uploading #{media_url}")
        next
      ensure
        file.close
        file.unlink
      end
    end
    return text
  end

  def clean_url(media_url)
    url = URI.parse(media_url)
    url.query = nil
    url = url.to_s
  end

  def media_url_for(media)
    if media.is_a? Twitter::Media::AnimatedGif
      return media.video_info.variants.first.url.to_s
    elsif media.is_a? Twitter::Media::Photo
      return media.media_url
    elsif media.is_a? Twitter::Media::Video
      return filter_videos_and_select_biggest_quality(media)
    end

    self.class.stats.increment('tweet.unknown_media')
    Rails.logger.warn { "Unknown media #{media.class.name}" }
    return nil
  end

  def filter_videos_and_select_biggest_quality(media)
    available = media.video_info.variants.select { |v|
      next false if v.content_type != 'video/mp4';
      h = HTTParty.head(v.url.to_s);
      next false if h['content-length'].to_i > 8.megabytes;
      next true
    }
    return available.max_by { |v| (v.bitrate.is_a?(Integer)? v.bitrate : -999) }.url.to_s unless available.empty?
  end

  def upload_media(media, file, retries = 3)
    returned_media = user.mastodon_client.upload_media(file)
    user.mastodon_client.update_media_description(returned_media.id, media.to_h[:ext_alt_text]) if media.to_h[:ext_alt_text].present?
    return returned_media.id
  rescue HTTP::Error => ex
    retry unless (retries -= 1).zero?
    raise ex
  rescue => ex
    raise UnknownMediaException.new(ex)
  end

  def define_visibility
    if @type == :quote
      @visibility = @user.twitter_quote_visibility
    elsif @type == :retweet
      @visibility = @user.twitter_retweet_visibility
    elsif @type == :original
      @visibility = @user.twitter_original_visibility
    end
  end

  def toot(text, medias, possibly_sensitive, save_status, content_warning)
    Rails.logger.debug { "Posting to Mastodon: #{text}" }
    opts = {media_ids: medias}
    opts[:sensitive]  = true if possibly_sensitive
    define_visibility
    opts[:visibility] = @visibility if @visibility.present?
    opts[:in_reply_to_id] = replied_status_id unless replied_status_id.nil?
    opts[:spoiler_text] = content_warning unless content_warning.nil?
    if @idempotency_key.nil?
      opts[:headers] = {'Idempotency-Key' => "#{user.mastodon.uid.split('@')[0]}-#{tweet.id}"}
    else
      opts[:headers] = {'Idempotency-Key' => @idempotency_key}
      @idempotency_key = nil
    end
    return if (text.length + (opts[:spoiler_text]&.size || 0)) > 500
    status = user.mastodon_client.create_status(text, opts)
    self.class.stats.increment('tweet.posted_to_mastodon')
    self.class.stats.timing('tweet.average_time_to_post', ((Time.now - tweet.created_at) * 1000).round(5))
    Status.create(mastodon_client: user.mastodon.mastodon_client, masto_id: status.id, tweet_id: tweet.id) if save_status
    status.id
  end
end
