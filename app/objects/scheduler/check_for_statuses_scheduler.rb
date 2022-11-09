# frozen_string_literal: true

class Scheduler::CheckForStatusesScheduler
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed, lock_ttl: 3.hours, retry: 0

  OLDER_THAN_IN_SECONDS = 30
  SLICE_SIZE = 100

  def perform
    # The crossposter was duplicating jobs in the queue and the issue seems to be that this method sometime takes a long time.
    # There's a lock_ttl with sidekiq unique jobs, but this also makes it so that in the case that fails, no users should be inserted twice.
    # This is achieved by first selecting all possible user ids, then iterating through them, selecting the user for update (to lock the row),
    # if the user at this point was locked, we skip the user_id.
    # Otherwise, we update the user_id and add the user to the queue.
    #
    # The update_all there is to avoid having to load the AR object in memory, since we just locked the row.
    user_ids = User.where("locked = ? AND (posting_from_mastodon = ? OR posting_from_twitter = ?) AND (mastodon_last_check < now() - interval '? seconds' or twitter_last_check < now() - interval '? seconds')", false, true, true, OLDER_THAN_IN_SECONDS, OLDER_THAN_IN_SECONDS).order(mastodon_last_check: :asc, twitter_last_check: :asc).pluck(:id)
    user_ids.each_slice(SLICE_SIZE) do |batch_user_ids|
      User.transaction do
        ids = User.where(id: batch_user_ids, locked: false).lock!.pluck(:id)
        next if ids.empty?

        User.where(id: ids).update_all(locked: true) # rubocop:disable Rails/SkipsModelValidations
        # We need to wait_until 1 second to avoid that jobs start executing while this transaction is not yet finished.
        # Ideally we need to avoid other workers from getting this instead, but this is a quick fix in the meantime
        ids.each { |user_id| ProcessUserWorker.set(wait_until: 1.second).perform_async(user_id) }
      end
    end
  end
end
