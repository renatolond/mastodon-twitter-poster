# frozen_string_literal: true

class Scheduler::CheckForStatusesScheduler
  include Sidekiq::Worker

  sidekiq_options unique: :until_executed, retry: 0

  OLDER_THAN_IN_SECONDS = 30

  def perform
      User.where('locked = ? AND (posting_from_mastodon = ? OR posting_from_twitter = ?) AND (mastodon_last_check < now() - interval \'? seconds\' or twitter_last_check < now() - interval \'? seconds\')', false, true, true, OLDER_THAN_IN_SECONDS, OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc, twitter_last_check: :asc).each do |user|
        u.locked = true; u.save
        ProcessUserWorker.perform_async(u.id)
      end
  end
end
