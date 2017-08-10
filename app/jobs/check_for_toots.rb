require 'mastodon_ext'
require 'toot_transformer'
class CheckForToots
  OLDER_THAN_IN_SECONDS = 30
  def self.available_since_last_check
    u = User.where('mastodon_last_check < now() - interval \'? seconds\'', OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc).first
    get_last_toots_for_user(u)
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
    new_toots.each do |t|
      process_toot(t, user)
    end
  end

  def self.process_toot(toot, user)
    #binding.pry
    if toot.is_direct?
      Rails.logger.debug('Ignoring direct toot. We do not treat them')
      # no sense in treating direct toots. could become an option in future, maybe.
      return
    elsif toot.is_reblog?
      process_boost(toot, user)
    elsif toot.is_reply?
      process_reply(toot, user)
    elsif toot.is_mention?
      process_mention(toot, user)
    else
      process_normal_toot(toot, user)
    end
  end

  def self.process_boost(toot, user)
    if user.masto_boost_do_not_post?
      Rails.logger.debug('Ignoring masto boost because user choose so')
      return
    elsif user.masto_boost_post_as_link?
      boost_as_link(toot, user)
    end
  end

  def self.boost_as_link(toot, user)
    content = "Boosted: #{toot.url}"
    if should_post(toot, user)
      tweet(content, user)
    else
      Rails.logger.debug('Ignoring boost because of visibility configuration')
    end
  end

  def self.process_reply(toot, user)
    if user.masto_reply_do_not_post?
      Rails.logger.debug('Ignoring masto reply because user choose so')
      return
    end
  end

  def self.process_mention(toot, user)
    if user.masto_mention_do_not_post?
      Rails.logger.debug('Ignoring masto mention because user choose so')
      return
    end
  end

  def self.process_normal_toot(toot, user)
    Rails.logger.debug{ "Processing toot: #{toot.text_content}" }
    if should_post(toot, user)
      tweet_content = TootTransformer.transform(toot.text_content, toot.url)
      tweet(tweet_content, user)
    else
      Rails.logger.debug('Ignoring boost because of visibility configuration')
    end
  end

  def self.should_post(toot, user)
    return true unless toot.is_unlisted? || toot.is_private?
    return true if toot.is_unlisted? && user.masto_should_post_unlisted?
    return true if toot.is_private? && user.masto_should_post_private?
    false
  end

  def self.tweet(content, user)
    Rails.logger.debug { "Posting to twitter: #{content}" }
  end
end
