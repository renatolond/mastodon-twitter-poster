require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'User\'s Mastodon domain' do
    expected_domain = 'my_domain.com'
    user = create(:user_with_mastodon_and_twitter, masto_domain: expected_domain)

    assert_equal "https://#{expected_domain}", user.mastodon_domain
  end

  # test "the truth" do
  #   assert true
  # end
end
