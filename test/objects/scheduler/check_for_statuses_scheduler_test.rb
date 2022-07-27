# frozen_string_literal: true

require "test_helper"

class CheckForStatusesSchedulerTest < ActiveSupport::TestCase
  def setup
    User.delete_all
    ProcessUserWorker.clear
  end

  test "If all user have been recently checked, no job is scheduled" do
    create(:user_with_mastodon_and_twitter, locked: false, posting_from_twitter: true, posting_from_mastodon: true, mastodon_last_check: 1.second.ago, twitter_last_check: 1.second.ago)

    Scheduler::CheckForStatusesScheduler.new.perform

    assert_equal 0, ProcessUserWorker.jobs.size
  end

  test "If a users has not been checked in the expected interval, a job is scheduled" do
    u1 = create(:user_with_mastodon_and_twitter, locked: false, posting_from_twitter: true, posting_from_mastodon: true, mastodon_last_check: 1.second.ago, twitter_last_check: 1.second.ago)
    u2 = create(:user_with_mastodon_and_twitter, locked: false, posting_from_twitter: true, posting_from_mastodon: true, mastodon_last_check: 1.minute.ago, twitter_last_check: 1.minute.ago)
    u3 = create(:user_with_mastodon_and_twitter, locked: false, posting_from_twitter: true, posting_from_mastodon: true, mastodon_last_check: 2.minutes.ago, twitter_last_check: 2.minutes.ago)

    Scheduler::CheckForStatusesScheduler.new.perform

    assert_equal 2, ProcessUserWorker.jobs.size
    u1.reload
    u2.reload
    u3.reload
    assert_not u1.locked
    assert u2.locked
    assert u3.locked
  end

  test "A user that has not been checked in the expected interval, but is not posting from either side does not get scheduled for check" do
    create(:user_with_mastodon_and_twitter, locked: false, posting_from_twitter: false, posting_from_mastodon: false, mastodon_last_check: 1.day.ago, twitter_last_check: 1.day.ago)

    Scheduler::CheckForStatusesScheduler.new.perform

    assert_equal 0, ProcessUserWorker.jobs.size
  end

  test "A user that has not been checked in the expected interval but is locked does not get scheduled for check" do
    create(:user_with_mastodon_and_twitter, locked: true, posting_from_twitter: true, posting_from_mastodon: false, mastodon_last_check: 1.day.ago, twitter_last_check: 1.day.ago)

    Scheduler::CheckForStatusesScheduler.new.perform

    assert_equal 0, ProcessUserWorker.jobs.size
  end
end
