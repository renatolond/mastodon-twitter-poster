require "mastodon_ext"
require "mastodon_user_processor"
require "twitter_user_processor"

class ProcessUserWorker
  include Sidekiq::Worker

  def self.stats
    @@stats ||= Stats.new
  end

  def perform(id)
    User.transaction do
      # Force the worker to wait for lock if other worker has it
      User.where(id:).lock!.pick(:id)
    end
    u = User.find(id)
    twitter_error = nil
    if u.posting_from_twitter
      begin
        self.class.stats.time("twitter.processing_time") { TwitterUserProcessor.process_user(u) }
      rescue Twitter::Error::Unauthorized, Mastodon::Error::Unauthorized, Mastodon::Error::Forbidden
        raise
      rescue => e
        Rails.logger.error { "Twitter errored out, will attempt to post from Mastodon -- #{e}" }
        twitter_error = e
      end
    end
    self.class.stats.time("mastodon.processing_time") { MastodonUserProcessor.process_user(u) } if u.posting_from_mastodon
    raise twitter_error if twitter_error

    u.locked = false
    u.save
  rescue Stoplight::Error::RedLight
    # If we're getting server errors, remove the user from the queue
    u.locked = false
    u.save
  rescue Twitter::Error::Unauthorized, Mastodon::Error::Unauthorized, Mastodon::Error::Forbidden
    UnauthorizedUserWorker.perform_async(id)
  end
end
