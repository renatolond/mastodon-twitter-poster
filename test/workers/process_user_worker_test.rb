# frozen_string_literal: true

require "test_helper"
require "minitest/mock"
require "mastodon_user_processor"
require "twitter_user_processor"

class ProcessUserWorkerTest < ActiveSupport::TestCase
  test "It calls both classes to process the user" do
    user = create(:user_with_twitter, posting_from_twitter: true, posting_from_mastodon: true, locked: true)

    TwitterUserProcessor.expects(:process_user).once
    MastodonUserProcessor.expects(:process_user).once

    Sidekiq::Testing.inline! do
      ProcessUserWorker.new.perform(user.id)
    end

    user.reload
    assert_not user.locked
  end
  test "If Twitter fails, still calls Mastodon but fails with twitter error" do
    user = create(:user_with_twitter, posting_from_twitter: true, posting_from_mastodon: true, locked: true)

    TwitterUserProcessor.expects(:process_user).raises(Twitter::Error::BadRequest)
    MastodonUserProcessor.expects(:process_user).once

    assert_raises Twitter::Error::BadRequest do
      Sidekiq::Testing.inline! do
        ProcessUserWorker.new.perform(user.id)
      end
    end

    user.reload
    assert user.locked
  end
  test "If Twitter fails, still calls Mastodon but if that fails too, fails with that error instead" do
    user = create(:user_with_twitter, posting_from_twitter: true, posting_from_mastodon: true, locked: true)

    TwitterUserProcessor.expects(:process_user).raises(Twitter::Error::BadRequest)
    MastodonUserProcessor.expects(:process_user).raises(Oj::ParseError)

    assert_raises Oj::ParseError do
      Sidekiq::Testing.inline! do
        ProcessUserWorker.new.perform(user.id)
      end
    end

    user.reload
    assert user.locked
  end
  test "Stoplight errors should remove user from the queue" do
    user = create(:user_with_twitter, posting_from_twitter: true, posting_from_mastodon: true, locked: true)

    TwitterUserProcessor.expects(:process_user).raises(Stoplight::Error::RedLight)
    MastodonUserProcessor.expects(:process_user).once

    Sidekiq::Testing.inline! do
      ProcessUserWorker.new.perform(user.id)
    end

    user.reload
    assert_not user.locked
  end
end
