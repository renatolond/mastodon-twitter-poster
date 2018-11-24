require "test_helper"

class AuthorizationCreationTest < ActiveSupport::TestCase
  test "Mastodon domain" do
    expected_domain = "my_domain.com"
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    ac = AuthorizationCreation.new(user.mastodon)

    assert_equal expected_domain, ac.mastodon_domain
  end
end
