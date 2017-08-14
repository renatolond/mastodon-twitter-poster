class UsersController < ApplicationController
  before_action :authenticate_user!
  def show
  end

  def update
    current_user.update_attributes!(user_params)
    flash[:success] = 'Your changes were saved.'
    redirect_to user_path
  end

  def user_params
    params.require(:user).permit(:posting_from_mastodon, :boost_options, :masto_reply_options, :masto_mention_options)
  end
end
