require ENV["RAILS_ENV_PATH"]
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
      u = User.where('locked = ? AND (posting_from_mastodon = ? OR posting_from_twitter = ?) AND (mastodon_last_check < now() - interval \'? seconds\' or twitter_last_check < now() - interval \'? seconds\')', false, true, true, OLDER_THAN_IN_SECONDS, OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc, twitter_last_check: :asc).first
      if u.nil?
        Rails.logger.debug { "No user to look at. Sleeping for #{SLEEP_FOR} seconds" }
        sleeper.sleep(SLEEP_FOR)
      else
        u.locked = true; u.save
        ProcessUserJob.perform_later(u.id)
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


CheckForToots::available_since_last_check
