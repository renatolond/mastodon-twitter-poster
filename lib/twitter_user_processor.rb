require 'stats'

class TwitterUserProcessor
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
        Rails.logger.error { "Could not process user #{user.twitter.uid}, toot #{t.id}. -- #{ex} -- Bailing out" }
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

  def self.process_normal_tweet(_tweet, _user)
    Rails.logger.debug('Ignoring normal tweet, not implemented')
    stats.increment("tweet.normal.skipped")
  end
end
