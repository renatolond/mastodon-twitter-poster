class UsersController < ApplicationController
  before_action :authenticate_user!
  def show
  end

  def update
    current_user.update_attributes!(user_params)
    flash[:success] = 'Your changes were saved.'
    redirect_to user_path
  rescue ActiveRecord::RecordInvalid => ex
    flash[:error] = ex.message
    redirect_to user_path
  end

  def user_params
    params.require(:user).permit(:posting_from_mastodon, :masto_should_post_private, :masto_should_post_unlisted, :boost_options, :masto_reply_options, :masto_mention_options, :masto_fix_cross_mention, :posting_from_twitter)
  end
end
