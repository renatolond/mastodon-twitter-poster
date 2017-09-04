require ENV["RAILS_ENV_PATH"]
require 'mastodon_ext'
require 'mastodon_user_processor'
require 'twitter_user_processor'
require 'toot_transformer'
require 'httparty'
require 'interruptible_sleep'

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
      u = User.where('(posting_from_mastodon = 1 OR posting_from_twitter = 1) AND (mastodon_last_check < now() - interval \'? seconds\' or twitter_last_check < now() - interval \'? seconds\')', true, true, OLDER_THAN_IN_SECONDS, OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc, twitter_last_check: :asc).first
      if u.nil?
        Rails.logger.debug { "No user to look at. Sleeping for #{SLEEP_FOR} seconds" }
        sleeper.sleep(SLEEP_FOR)
      else
        MastodonUserProcessor::process_user(u) if u.posting_from_mastodon
        TwitterUserProcessor::process_user(u) if u.posting_from_twitter
      end
      break if finished
    end
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

twitter_client = Twitter::REST::Client.new do |config|
  config.consumer_key = ENV['TWITTER_CLIENT_ID']
  config.consumer_secret = ENV['TWITTER_CLIENT_SECRET']
end

begin
  TootTransformer::twitter_short_url_length = twitter_client.configuration.short_url_length
  TootTransformer::twitter_short_url_length_https = twitter_client.configuration.short_url_length_https
rescue Twitter::Error::Forbidden
  Rails.logger.error { "Missing Twitter credentials" }
  exit
end


CheckForToots::available_since_last_check
