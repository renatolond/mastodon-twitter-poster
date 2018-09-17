require 'test_helper'
require 'minitest/mock'

class UserTest < ActiveSupport::TestCase
  test 'Mastodon domain' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    assert_equal "https://#{expected_domain}", user.mastodon_domain
  end

  test 'Mastodon id' do
    user = build(:user_with_mastodon_and_twitter)
    expected_id = 123

    mastodon_client = mock()
    mastodon_client.expects(:verify_credentials).at_least(1).returns(mastodon_client)
    mastodon_client.expects(:id).at_least(1).returns(expected_id)
    user.expects(:mastodon_client).returns(mastodon_client)

    id = user.mastodon_id
    assert_equal expected_id, id
  end

  test 'Mastodon client' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    mastodon_client = mock()
    Mastodon::REST::Client.expects(:new).with({base_url: "https://#{expected_domain}", bearer_token: user.mastodon.token}).returns(mastodon_client)

    m = user.mastodon_client
    assert_equal mastodon_client, m
  end

  test 'Twitter client' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)
    twitter_client_id = 'MYCLIENTID'
    twitter_client_secret = 'SECRET!'

    twitter_client = mock()
    config = mock()
    config.expects(:consumer_key=).with(twitter_client_id)
    config.expects(:consumer_secret=).with(twitter_client_secret)
    config.expects(:access_token=).with(user.twitter.token)
    config.expects(:access_token_secret=).with(user.twitter.secret)
    User.expects(:twitter_client_id).returns(twitter_client_id)
    User.expects(:twitter_client_secret).returns(twitter_client_secret)
    Twitter::REST::Client.expects(:new).yields(config).returns(twitter_client)

    t = user.twitter_client
    assert_equal twitter_client, t
  end

  test 'Save last tweet id in a user that already has last_tweet' do
    user = create(:user_with_mastodon_and_twitter, last_tweet: 9999998)
    expected_tweet_status_id = 9999999

    twitter_client = mock()
    user.expects(:twitter_client).returns(twitter_client)
    status = mock()
    status.expects(:id).returns(expected_tweet_status_id)
    twitter_client.expects(:user_timeline).with({count: 1}).returns([status])

    user.save_last_tweet_id
    assert_equal expected_tweet_status_id, user.last_tweet
  end

  test 'Save last tweet id in a profile without statuses' do
    user = create(:user_with_mastodon_and_twitter, last_tweet: nil)

    twitter_client = mock()
    user.expects(:twitter_client).returns(twitter_client)
    twitter_client.expects(:user_timeline).with({count: 1}).returns([])

    user.save_last_tweet_id
    assert_nil user.last_tweet
  end

  test 'Save last tweet id in a profile with statuses' do
    user = create(:user_with_mastodon_and_twitter, last_tweet: nil)
    expected_tweet_status_id = 9999999

    twitter_client = mock()
    user.expects(:twitter_client).returns(twitter_client)
    status = mock()
    status.expects(:id).returns(expected_tweet_status_id)
    twitter_client.expects(:user_timeline).with({count: 1}).returns([status])

    user.save_last_tweet_id
    assert_equal expected_tweet_status_id, user.last_tweet
  end

  test 'Save last toot id in a user that already has last_toot' do
    user = create(:user_with_mastodon_and_twitter, last_toot: 2001)
    expected_mastodon_status_id = 2002
    mastodon_id = 123

    mastodon_client = mock()
    user.expects(:mastodon_client).returns(mastodon_client)
    user.expects(:mastodon_id).returns(mastodon_id)
    mastodon_status = mock()
    mastodon_client.expects(:statuses).with(mastodon_id, {limit: 1}).returns([mastodon_status])
    mastodon_status.expects(:id).returns(expected_mastodon_status_id)

    user.save_last_toot_id
    assert_equal expected_mastodon_status_id, user.last_toot
  end

  test 'Save last toot id in a profile without statuses' do
    user = create(:user_with_mastodon_and_twitter, last_toot: nil)
    mastodon_id = 123

    mastodon_client = mock()
    user.expects(:mastodon_client).returns(mastodon_client)
    user.expects(:mastodon_id).returns(mastodon_id)
    mastodon_client.expects(:statuses).with(mastodon_id, {limit: 1}).returns([])

    user.save_last_toot_id
    assert_nil user.last_toot
  end

  test 'Save last toot id in a profile with statuses' do
    user = create(:user_with_mastodon_and_twitter, last_toot: nil)
    mastodon_id = 123
    expected_mastodon_status_id = 2002

    mastodon_client = mock()
    user.expects(:mastodon_client).returns(mastodon_client)
    user.expects(:mastodon_id).returns(mastodon_id)
    mastodon_status = mock()
    mastodon_client.expects(:statuses).with(mastodon_id, {limit: 1}).returns([mastodon_status])
    mastodon_status.expects(:id).returns(expected_mastodon_status_id)

    user.save_last_toot_id
    assert_equal expected_mastodon_status_id, user.last_toot
  end

  test 'Omniauth with no previous user, allowing new users' do
    expected_domain = 'my_domain.com'

    authorization = build(:authorization_mastodon, uid: "user@#{expected_domain}", secret: 'oh-my-secret!')
    mastodon_client = create(:mastodon_client, domain: expected_domain).reload
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(authorization.provider)
    auth.expects(:uid).at_least(1).returns(authorization.uid)
    auth.expects(:credentials).at_least(1).returns(credentials)
    credentials.expects(:token).returns(authorization.token)
    credentials.expects(:secret).returns(authorization.secret)
    user_mastodon_client = mock()
    Mastodon::REST::Client.expects(:new).with({base_url: "https://#{expected_domain}", bearer_token: authorization.token}).returns(user_mastodon_client)
    user_mastodon_client.expects(:verify_credentials).at_least(1).returns(user_mastodon_client)
    user_mastodon_client.expects(:id).returns(1234)
    user_mastodon_client.expects(:statuses).with(1234, {limit: 1}).returns([])
    User.expects(:do_not_allow_users).returns(nil)

    u = User.from_omniauth(auth, nil)
    assert_equal User.last, u
    assert_equal authorization.provider, u.mastodon.provider
    assert_equal authorization.uid, u.mastodon.uid
    assert_equal authorization.token, u.mastodon.token
    assert_equal authorization.secret, u.mastodon.secret
    assert_equal mastodon_client.id, u.mastodon.mastodon_client_id
  end

  test 'Omniauth with no previous user, not allowing new users' do
    expected_domain = 'my_domain.com'

    authorization = build(:authorization_mastodon, uid: "user2@#{expected_domain}")
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(authorization.provider)
    auth.expects(:uid).at_least(1).returns(authorization.uid)
    User.expects(:do_not_allow_users).returns('1')

    u = User.from_omniauth(auth, nil)
    assert_nil u
  end

  test 'Omniauth with previous user' do
    expected_domain = 'my_domain.com'

    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(user.twitter.provider)
    auth.expects(:uid).at_least(1).returns(user.twitter.uid)
    auth.expects(:credentials).at_least(1).returns(credentials)
    credentials.expects(:token).returns(user.twitter.token)
    credentials.expects(:secret).returns(user.twitter.secret)
    User.expects(:do_not_allow_users).returns(nil)
    User.any_instance.stubs(:save_last_tweet_id)

    u = User.from_omniauth(auth, nil)
    assert_equal user, u
  end

  test 'User changes domain and toot counter is not reset' do
    user = create(:user_with_mastodon_and_twitter, last_toot: 20010010)

    authorization = build(:authorization_mastodon, uid: user.mastodon.uid, token: 'super-crazy-token')
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(authorization.provider)
    auth.expects(:uid).at_least(1).returns(authorization.uid)
    auth.expects(:credentials).at_least(1).returns(credentials)
    credentials.expects(:token).returns(authorization.token)
    credentials.expects(:secret).returns(authorization.secret)

    mastodon_id = 123
    expected_mastodon_status_id = 2
    mastodon_client = mock()
    user.expects(:mastodon_client).returns(mastodon_client)
    user.expects(:mastodon_id).returns(mastodon_id)
    mastodon_status = mock()
    mastodon_client.expects(:statuses).with(mastodon_id, {limit: 1}).returns([mastodon_status])
    mastodon_status.expects(:id).returns(expected_mastodon_status_id)

    u = User.from_omniauth(auth, user)
    assert_not_equal 20010010, u.last_toot
    assert_equal expected_mastodon_status_id, u.last_toot
  end
end
