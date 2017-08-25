require 'test_helper'
require 'minitest/mock'

class UserTest < ActiveSupport::TestCase
  test 'Mastodon domain' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    assert_equal "https://#{expected_domain}", user.mastodon_domain
  end

  test 'Mastodon Client' do
    user = build(:user_with_mastodon_and_twitter)
    expected_id = 123

    mastodon_client = mock()
    mastodon_client.expects(:verify_credentials).at_least(1).returns(mastodon_client)
    mastodon_client.expects(:id).at_least(1).returns(expected_id)
    user.stub :mastodon_client, mastodon_client do
      id = user.mastodon_id
      assert_equal expected_id, id
    end
  end

  test 'Mastodon client' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    mastodon_client = mock()
    mastodon_client.expects(:call).at_least(1).with({base_url: "https://#{expected_domain}", bearer_token: user.mastodon.token}).returns(mastodon_client)
    Mastodon::REST::Client.stub :new, mastodon_client do
      m = user.mastodon_client
      assert_equal mastodon_client, m
    end
  end

  test 'Mastodon omniauth with no previous user, allowing new users' do
    expected_domain = 'my_domain.com'

    authorization = build(:authorization_mastodon, uid: "user@#{expected_domain}")
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(authorization.provider)
    auth.expects(:uid).at_least(1).returns(authorization.uid)
    auth.expects(:credentials).at_least(1).returns(credentials)
    credentials.expects(:token).returns(authorization.token)
    credentials.expects(:secret).returns(authorization.secret)

    mastodon_client = mock()
    mastodon_client.expects(:call).at_least(1).with({base_url: "https://#{expected_domain}", bearer_token: authorization.token}).returns(mastodon_client)
    mastodon_client.expects(:verify_credentials).at_least(1).returns(mastodon_client)
    mastodon_client.expects(:id).at_least(1).returns(123)
    mastodon_client.expects(:statuses).at_least(1).with(123, {limit: 1}).returns([])

    Mastodon::REST::Client.stub :new, mastodon_client do
      User.stub :do_not_allow_users, nil do
        u = User.from_omniauth(auth, nil)
        assert_equal User.last, u
        assert_equal authorization.provider, u.mastodon.provider
        assert_equal authorization.uid, u.mastodon.uid
        assert_equal authorization.token, u.mastodon.token
        assert_equal authorization.secret, u.mastodon.secret
      end
    end
  end

  test 'Mastodon omniauth with no previous user, not allowing new users' do
    expected_domain = 'my_domain.com'

    authorization = build(:authorization_mastodon, uid: "user2@#{expected_domain}")
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(authorization.provider)
    auth.expects(:uid).at_least(1).returns(authorization.uid)

    User.stub :do_not_allow_users, '1' do
      u = User.from_omniauth(auth, nil)
      assert_nil u
    end
  end

  test 'Mastodon omniauth with previous user' do
    expected_domain = 'my_domain.com'

    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)
    auth = mock()
    credentials = mock()
    auth.expects(:provider).at_least(1).returns(user.mastodon.provider)
    auth.expects(:uid).at_least(1).returns(user.mastodon.uid)
    auth.expects(:credentials).at_least(1).returns(credentials)
    credentials.expects(:token).returns(user.mastodon.token)
    credentials.expects(:secret).returns(user.mastodon.secret)

    User.stub :do_not_allow_users, nil do
      u = User.from_omniauth(auth, nil)
      assert_equal user, u
    end
  end
end
