# frozen_string_literal: true

class Scheduler::CheckForStatusesScheduler
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 3.hours, retry: 0

  OLDER_THAN_IN_SECONDS = 30

  def perform
    User.where("locked = ? AND (posting_from_mastodon = ? OR posting_from_twitter = ?) AND (mastodon_last_check < now() - interval '? seconds' or twitter_last_check < now() - interval '? seconds')", false, true, true, OLDER_THAN_IN_SECONDS, OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc, twitter_last_check: :asc).each do |user|
      user.locked = true; user.save
      ProcessUserWorker.perform_async(user.id)
    end
  end
end
