# frozen_string_literal: true

class Scheduler::CheckForStatusesScheduler
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 3.hours, retry: 0

  OLDER_THAN_IN_SECONDS = 30

  def perform
    # The crossposter was duplicating jobs in the queue and the issue seems to be that this method sometime takes a long time.
    # There's a lock_ttl with sidekiq unique jobs, but this also makes it so that in the case that fails, no users should be inserted twice.
    # This is achived by first selecting all possible user ids, then iterating through them, selecting the user for update (to lock the row),
    # if the user at this point was locked, we skip the user_id.
    # Otherwise, we update the user_id and add the user to the queue.
    #
    # The update_all there is to avoid having to load the AR object in memory, since we just locked the row.
    user_ids = User.where("locked = ? AND (posting_from_mastodon = ? OR posting_from_twitter = ?) AND (mastodon_last_check < now() - interval '? seconds' or twitter_last_check < now() - interval '? seconds')", false, true, true, OLDER_THAN_IN_SECONDS, OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc, twitter_last_check: :asc).pluck(:id)
    user_ids.each do |user_id|
      User.transaction do
        locked = User.where(id: user_id).lock!.pick(:locked)
        next if locked

        User.where(id: user_id).update_all(locked: true) # rubocop:disable Rails/SkipsModelValidations
        ProcessUserWorker.perform_async(user_id)
      end
    end
  end
end
