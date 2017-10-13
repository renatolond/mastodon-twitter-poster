require 'stats'

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
    rescue StandardError => ex
      Rails.logger.error { "Could not process user #{user.twitter.uid}. -- #{ex} -- Bailing out" }
      stats.increment("user.processing_error")
    ensure
      user.twitter_last_check = Time.now
      user.mastodon_last_check = Time.now # XXX remove this when possible to post from both networks at same time
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

    new_tweets = user.twitter_client.user_timeline(user_timeline_options(user))
    last_successful_tweet = nil
    new_tweets.reverse.each do |t|
      begin
        process_tweet(t, user)
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

  def self.process_tweet(tweet, user)
    if(tweet.retweet? || tweet.text[0..3] == 'RT @')
      process_retweet(tweet, user)
    elsif tweet.reply?
      process_reply(tweet, user)
    else
      process_normal_tweet(tweet, user)
    end
  end

  def self.process_retweet(_tweet, _user)
    Rails.logger.debug('Ignoring retweet, not implemented')
    stats.increment("tweet.retweet.skipped")
  end

  def self.process_reply(_tweet, _user)
    Rails.logger.debug('Ignoring reply, not implemented')
    stats.increment("tweet.reply.skipped")
  end

  def self.process_normal_tweet(tweet, user)
    text = replace_links(tweet)
    text = replace_mentions(text)
    text, medias, media_links = find_media(tweet, user, text)
    text = self.html_entities.decode(text)
    text = media_links.join("\n") if text.empty?
    toot(text, medias, tweet.possibly_sensitive?, user)
  end

  def self.find_media(tweet, user, text)
    medias = []
    media_links = []
    tweet.media.each do |media|
      media_url = nil
      if media.is_a? Twitter::Media::AnimatedGif
        media_url = media.video_info.variants.first.url.to_s
      elsif media.is_a? Twitter::Media::Photo
        media_url = media.media_url
      else
        stats.increment('tweet.unknown_media')
        Rails.logger.warn { "Unknown media #{media.class.name}" }
        next
      end
      text.gsub!(media.url, '').strip!
      url = URI.parse(media_url)
      url.query = nil
      url = url.to_s
      file = Tempfile.new(['media', File.extname(url)], "#{Rails.root}/tmp")
      file.binmode
      begin
        file.write HTTParty.get(media_url).body
        file.rewind
        media = user.mastodon_client.upload_media(file)
        media_links << media.text_url
        medias << media.id
      ensure
        file.close
        file.unlink
      end
    end
    return text, medias, media_links
  end

  def self.replace_mentions(text)
    twitter_mention_regex = /(\s|^)(@[A-Za-z0-9_]+)([^A-Za-z0-9_]|$)/
    text.gsub(twitter_mention_regex, '\1\2@twitter.com\3')
  end

  def self.replace_links(tweet)
    text = tweet.text.dup
    tweet.urls.each do |u|
      text.gsub!(u.url.to_s, u.expanded_url.to_s)
    end
    text
  end

  def self.toot(text, medias, possibly_sensitive, user)
    Rails.logger.debug { "Posting to Mastodon: #{text}" }
    stats.increment('tweet.posted_to_mastodon')
    user.mastodon_client.create_status(text, sensitive: possibly_sensitive, media_ids: medias)
  end
end
