# frozen_string_literal: true

require 'test_helper'

class CleanupTest < ActiveSupport::TestCase
  test 'Users without mastodon accounts get their crossposting turned off' do
    authorization_masto = build(:authorization_mastodon, uid: 'a-user@masto.domain', masto_domain: 'masto.domain')
    authorization_twitter = build(:authorization_twitter)
    user_with_both = create(:user, authorizations: [authorization_masto, authorization_twitter], posting_from_mastodon: true, posting_from_twitter: true)

    another_authorization_twitter = build(:authorization_twitter)
    user_without_mastodon = create(:user, authorizations: [another_authorization_twitter], posting_from_mastodon: true, posting_from_twitter: true)

    Cleanup.new.call

    user_without_mastodon.reload
    user_with_both.reload

    assert user_with_both.posting_from_twitter
    assert user_with_both.posting_from_mastodon

    refute user_without_mastodon.posting_from_twitter
    refute user_without_mastodon.posting_from_mastodon
  end

  test 'Users without twitter accounts get their crossposting turned off' do
    authorization_masto = build(:authorization_mastodon, uid: 'a-user@masto.domain', masto_domain: 'masto.domain')
    authorization_twitter = build(:authorization_twitter)
    user_with_both = create(:user, authorizations: [authorization_masto, authorization_twitter], posting_from_mastodon: true, posting_from_twitter: true)

    another_authorization_masto = build(:authorization_mastodon, uid: 'another-user@other.masto.domain', masto_domain: 'other.masto.domain')
    user_without_twitter = create(:user, authorizations: [another_authorization_masto], posting_from_mastodon: true, posting_from_twitter: true)

    Cleanup.new.call

    user_without_twitter.reload
    user_with_both.reload

    assert user_with_both.posting_from_twitter
    assert user_with_both.posting_from_mastodon

    refute user_without_twitter.posting_from_twitter
    refute user_without_twitter.posting_from_mastodon
  end

  test 'Disabled users gone longer than two weeks get removed' do
    user_older_than_two_weeks = nil
    Timecop.travel(3.weeks.ago) do
      user_older_than_two_weeks = create(:user_with_mastodon_and_twitter, posting_from_mastodon: false, posting_from_twitter: false)
    end
    recently_created_user = create(:user_with_mastodon_and_twitter, posting_from_mastodon: false, posting_from_twitter: false)

    assert_difference 'Authorization.count', -2 do assert_difference 'User.count', -1 do Cleanup.new.call end end

    assert_raises ActiveRecord::RecordNotFound do
      user_older_than_two_weeks.reload
    end
    recently_created_user.reload
  end

  test 'Statuses crossposted more than a year ago get removed' do
    user = create(:user_with_mastodon_and_twitter)
    status_older_than_a_year = nil
    Timecop.travel(13.months.ago) do
      status_older_than_a_year = create(:status, mastodon_client: user.mastodon.mastodon_client)
    end

    status_newer_than_a_year = create(:status, mastodon_client: user.mastodon.mastodon_client)

    assert_difference 'Status.count', -1 do Cleanup.new.call end

    assert_raises ActiveRecord::RecordNotFound do
      status_older_than_a_year.reload
    end

    status_newer_than_a_year.reload
  end

  test 'Mastodon domains without users get removed, and any status belonging to them too' do
    mastodon_client = create(:mastodon_client)
    user = create(:user_with_mastodon_and_twitter)
    user_mastodon_client = user.mastodon.mastodon_client

    status = create(:status, mastodon_client: mastodon_client)
    user_status = create(:status, mastodon_client: user_mastodon_client)

    assert_difference ['Status.count', 'MastodonClient.count'], -1 do Cleanup.new.call end

    assert_raises ActiveRecord::RecordNotFound do
      mastodon_client.reload
    end
    assert_raises ActiveRecord::RecordNotFound do
      status.reload
    end

    user_mastodon_client.reload
    user_status.reload
  end
end
