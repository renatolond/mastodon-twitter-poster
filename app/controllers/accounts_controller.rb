class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
    @authorizations = current_user.authorizations
  end
end
