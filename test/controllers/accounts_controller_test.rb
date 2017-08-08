require 'test_helper'

class AccountsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get accounts_show_url
    assert_response :success
  end

end
