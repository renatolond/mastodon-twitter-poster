require ENV["RAILS_ENV_PATH"]
require 'twitter_user_processor'
require 'interruptible_sleep'

class CheckForTweets
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
      u = User.where('twitter_last_check < now() - interval \'? seconds\'', OLDER_THAN_IN_SECONDS).order(twitter_last_check: :asc).first
      if u.nil?
        Rails.logger.debug { "No user to look at. Sleeping for #{SLEEP_FOR} seconds" }
        sleeper.sleep(SLEEP_FOR)
      else
        TwitterUserProcessor::process_user(u)
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
CheckForTweets::available_since_last_check
