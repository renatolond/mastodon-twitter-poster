require ENV["RAILS_ENV_PATH"]
require 'mastodon_ext'
require 'toot_transformer'

class InterruptibleSleep
  def sleep(seconds)
    @_sleep_check, @_sleep_interrupt = IO.pipe
    IO.select([@_sleep_check], nil, nil, seconds)
  end

  def wakeup
    @_sleep_interrupt.close if @_sleep_interrupt && !@_sleep_interrupt.closed?
  end
end


class CheckForToots
  OLDER_THAN_IN_SECONDS = 30
  SLEEP_FOR = 60
  def self.finished=(f)
    @@finished = f
  end
  def self.finished
    @@finished ||= false
  end

  def self.sleeper
    @@sleeper ||= InterruptibleSleep.new
  end

  def self.available_since_last_check
    loop do
      u = User.where('mastodon_last_check < now() - interval \'? seconds\'', OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc).first
      if u.nil?
        Rails.logger.debug { "No user to look at. Sleeping for #{SLEEP_FOR} seconds" }
        sleeper.sleep(SLEEP_FOR)
      else
        begin
          get_last_toots_for_user(u) if u.posting_from_mastodon
        rescue => ex
          Rails.logger.error { "Could not process user #{u.mastodon.uid}. -- #{ex} -- Bailing out" }
        ensure
          u.mastodon_last_check = Time.now
          u.save
        end
      end
      break if finished
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
        process_toot(t, user)
        last_sucessful_toot = t
      rescue => ex
        Rails.logger.error { "Could not process user #{user.mastodon.uid}, toot #{t.id}. -- #{ex} -- Bailing out" }
        break
      end
    end

    user.last_toot = last_sucessful_toot.id unless last_sucessful_toot.nil?
    user.mastodon_last_check = Time.now
    user.save
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
      tweet_content = TootTransformer.transform(toot_content_to_post(toot), toot.url, user.masto_fix_cross_mention)
      tweet(tweet_content, user)
    else
      Rails.logger.debug('Ignoring normal toot because of visibility configuration')
    end
  end

  def self.toot_content_to_post(toot)
    if toot.sensitive?
      "CW: #{toot.spoiler_text} … #{toot.url}"
    else
      toot.text_content
    end
  end

  def self.should_post(toot, user)
    if toot.is_public? ||
        (toot.is_unlisted? && user.masto_should_post_unlisted?) ||
        (toot.is_private? && user.masto_should_post_private?)
      true
    else
      false
    end
  end

  def self.tweet(content, user)
    Rails.logger.debug { "Posting to twitter: #{content}" }
    user.twitter_client.update(content)
  end
end

Signal.trap("TERM") {
  CheckForToots::finished = true
  CheckForToots::sleeper.wakeup
}
Signal.trap("INT") {
  CheckForToots::finished = true
  CheckForToots::sleeper.wakeup
}

Rails.logger.debug { "Starting" }

CheckForToots::available_since_last_check
