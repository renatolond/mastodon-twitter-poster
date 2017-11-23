class UsersController < ApplicationController
  before_action :authenticate_user!
  def show
  end

  def update
    current_user.update_attributes!(user_params)
    changes = current_user.previous_changes
    update_last_tweet_if_needed(changes)
    update_last_toot_if_needed(changes)
    flash[:success] = 'Your changes were saved.'
    redirect_to user_path
  rescue ActiveRecord::RecordInvalid => ex
    flash[:error] = ex.message
    redirect_to user_path
  end

  def user_params
    params.require(:user).permit(:posting_from_mastodon, :masto_should_post_private, :masto_should_post_unlisted, :boost_options, :masto_reply_options, :masto_mention_options, :masto_fix_cross_mention, :posting_from_twitter, :retweet_options, :quote_options, :twitter_reply_options)
  end

  private

  def update_last_tweet_if_needed(changes)
    if current_user.posting_from_twitter && current_user.twitter && changes.has_key?('posting_from_twitter')
      current_user.save_last_tweet_id
    end
  end

  def update_last_toot_if_needed(changes)
    if current_user.posting_from_mastodon && current_user.mastodon && changes.has_key?('posting_from_mastodon')
      current_user.save_last_toot_id
    end
  end
end
