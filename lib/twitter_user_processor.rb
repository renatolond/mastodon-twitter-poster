require 'stats'
require 'tweet_transformer'

class TwitterUserProcessor
  def self.html_entities
    @@html_entities ||= HTMLEntities.new
  end

  def self.stats
    @@stats ||= Stats.new
  end

  def self.process_user(user)
    begin
      get_last_tweets_for_user(user) if user.posting_from_twitter
    rescue HTTP::Error => ex
      if ex.message == 'Unknown MIME type: text/html'
        Rails.logger.warn { "Domain #{user.mastodon.mastodon_client.domain} seems offline" }
        stats.increment('domain.offline')
      else
        Rails.logger.error { "Could not process user #{user.twitter.uid}. -- #{ex} -- Bailing out" }
        stats.increment("user.processing_error")
      end
    rescue StandardError => ex
      Rails.logger.error { "Could not process user #{user.twitter.uid}. -- #{ex} -- Bailing out" }
      stats.increment("user.processing_error")
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
      rescue StandardError => ex
        Rails.logger.error { "Could not process user #{user.twitter.uid}, tweet #{t.id}. -- #{ex} -- Bailing out" }
        stats.increment("tweet.processing_error")
        break
      end
    end

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
    if user.retweet_do_not_post?
      Rails.logger.debug('Ignoring retweet because user chose so')
      self.class.stats.increment("tweet.retweet.skipped")
    elsif user.retweet_post_as_link?
      content = "RT: #{tweet.url}"
      save_status = true
      toot(content, [], tweet.possibly_sensitive?, save_status)
    elsif user.retweet_post_as_old_rt?
      retweet = tweet.retweeted_status
      text, medias = convert_twitter_text(tweet.full_text.dup, tweet.urls + retweet.urls, (tweet.media + retweet.media).uniq)
      save_status = true
      toot(text, medias, tweet.possibly_sensitive?, save_status)
    end
  end

  def process_quote
    if user.quote_do_not_post?
      Rails.logger.debug('Ignoring quote because user chose so')
      self.class.stats.increment("tweet.quote.skipped")
    elsif user.quote_post_as_link?
      process_normal_tweet
    elsif user.quote_post_as_old_rt?
      process_quote_as_old_rt
    end
  end

  def process_quote_as_old_rt
      quote = tweet.quoted_status
      full_text = "#{tweet.full_text.gsub(" #{tweet.urls.first.url}", '')}\nRT @#{quote.user.screen_name} #{quote.full_text}"
      text, medias = convert_twitter_text(full_text, tweet.urls + quote.urls, (tweet.media + quote.media).uniq)
      if text.length <= 500
        save_status = true
        toot(text, medias, tweet.possibly_sensitive?, save_status)
      else
        text, medias = convert_twitter_text("RT @#{quote.user.screen_name} #{quote.full_text}", quote.urls, quote.media)
        save_status = false
        quote_id = toot(text, medias, quote.possibly_sensitive?, save_status)
        text, medias = convert_twitter_text(tweet.full_text.gsub(" #{tweet.urls.first.url}", ''), tweet.urls, tweet.media)
        save_status = true
        self.replied_status_id = quote_id
        toot(text, medias, tweet.possibly_sensitive?, save_status)
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
      text, medias = convert_twitter_text(tweet.full_text.dup, tweet.urls, tweet.media)
      save_status = true
      toot(text, medias, tweet.possibly_sensitive?, save_status)
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
    text, medias, media_links = find_media(media, text)
    text = self.class.html_entities.decode(text)
    text = media_links.join("\n") if text.empty?
    [text, medias]
  end

  def process_normal_tweet
    text, medias = convert_twitter_text(tweet.full_text.dup, tweet.urls, tweet.media)
    save_status = true
    toot(text, medias, tweet.possibly_sensitive?, save_status)
  end

  def find_media(tweet_medias, text)
    medias = []
    media_links = []
    tweet_medias.each do |media|
      media_url = nil
      if media.is_a? Twitter::Media::AnimatedGif
        media_url = media.video_info.variants.first.url.to_s
      elsif media.is_a? Twitter::Media::Photo
        media_url = media.media_url
      else
        self.class.stats.increment('tweet.unknown_media')
        Rails.logger.warn { "Unknown media #{media.class.name}" }
        next
      end
      text = text.gsub(media.url, '').strip
      url = URI.parse(media_url)
      url.query = nil
      url = url.to_s
      file = Tempfile.new(['media', File.extname(url)], "#{Rails.root}/tmp")
      file.binmode
      begin
        file.write HTTParty.get(media_url).body
        file.rewind
        returned_media = nil
        begin
          returned_media = user.mastodon_client.upload_media(file, media.to_h[:ext_alt_text])
        rescue => ex
          Rails.logger.error("Caught exception #{ex} when posting alt_text #{media.to_h[:ext_alt_text]}")
          returned_media = user.mastodon_client.upload_media(file)
        end
        media_links << returned_media.text_url
        medias << returned_media.id
      ensure
        file.close
        file.unlink
      end
    end
    return text, medias, media_links
  end

  def toot(text, medias, possibly_sensitive, save_status)
    Rails.logger.debug { "Posting to Mastodon: #{text}" }
    opts = {sensitive: possibly_sensitive, media_ids: medias}
    opts[:in_reply_to_id] = replied_status_id unless replied_status_id.nil?
    status = user.mastodon_client.create_status(text, opts)
    self.class.stats.increment('tweet.posted_to_mastodon')
    Status.create(mastodon_client: user.mastodon.mastodon_client, masto_id: status.id, tweet_id: tweet.id) if save_status
    status.id
  end
end
