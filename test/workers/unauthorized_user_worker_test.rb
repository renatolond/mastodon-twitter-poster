# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class UnauthorizedUserWorkerTest < ActiveSupport::TestCase
  test "Unauthorized twitter error without the correct code is ignored" do
    user = create(:user_with_twitter, posting_from_twitter: true)
    twitter_client = mock()
    user.expects(:twitter_client).returns(twitter_client)
    User.expects(:find).with(user.id).returns(user)
    twitter_client.expects(:verify_credentials).raises(Twitter::Error::Unauthorized)

    Sidekiq::Testing.inline! do
      UnauthorizedUserWorker.perform_async(user.id)
    end

    assert_equal 1, user.authorizations.count
    assert user.posting_from_twitter
  end

  test "Unauthorized twitter error with the correct code remove twitter and stops crossposting" do
    user = create(:user_with_twitter, posting_from_twitter: true)
    twitter_client = mock()
    user.expects(:twitter_client).returns(twitter_client)
    User.expects(:find).with(user.id).returns(user)
    err = Twitter::Error::Unauthorized.new("blah", {}, 89)
    twitter_client.expects(:verify_credentials).raises(err)

    Sidekiq::Testing.inline! do
      UnauthorizedUserWorker.perform_async(user.id)
    end

    assert_equal 0, user.authorizations.count
    assert_not user.posting_from_twitter
  end

  test "Unauthorized mastodon error without the correct message is ignored" do
    user = create(:user_with_mastodon, posting_from_mastodon: true)
    mastodon_client = mock()
    user.expects(:mastodon_client).returns(mastodon_client)
    User.expects(:find).with(user.id).returns(user)
    mastodon_client.expects(:verify_credentials).raises(Mastodon::Error::Unauthorized)

    Sidekiq::Testing.inline! do
      UnauthorizedUserWorker.perform_async(user.id)
    end

    assert_equal 1, user.authorizations.count
    assert user.posting_from_mastodon
  end

  test "Unauthorized mastodon error with the correct message removes mastodon and stops crossposting" do
    user = create(:user_with_mastodon, posting_from_mastodon: true)
    mastodon_client = mock()
    user.expects(:mastodon_client).returns(mastodon_client)
    User.expects(:find).with(user.id).returns(user)
    err = Mastodon::Error::Unauthorized.new("The access token was revoked")
    mastodon_client.expects(:verify_credentials).raises(err)

    Sidekiq::Testing.inline! do
      UnauthorizedUserWorker.perform_async(user.id)
    end

    assert_equal 0, user.authorizations.count
    assert_not user.posting_from_mastodon
  end

  test "User not found, ignore" do
    user_id = 999
    User.expects(:find).with(user_id).raises(ActiveRecord::RecordNotFound)

    Sidekiq::Testing.inline! do
      UnauthorizedUserWorker.perform_async(user_id)
    end
  end
end
