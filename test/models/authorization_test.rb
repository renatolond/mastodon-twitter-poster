require 'test_helper'

class AuthorizationTest < ActiveSupport::TestCase
  test 'Mastodon domain' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    assert_equal expected_domain, user.mastodon.send(:mastodon_domain)
  end
end
