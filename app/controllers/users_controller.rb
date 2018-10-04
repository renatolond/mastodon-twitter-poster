class UsersController < ApplicationController
  before_action :authenticate_user!, except: :mastodon_identifier
  def show
  end

  def advanced_mastodon
  end

  def advanced_twitter
  end

  def update
    current_user.update_attributes!(user_params)
    changes = current_user.previous_changes
    update_last_tweet_if_needed(changes)
    update_last_toot_if_needed(changes)
    flash[:success] = 'Your changes were saved.'
    redirect_to find_path
  rescue ActiveRecord::RecordInvalid => ex
    flash[:error] = ex.message
    redirect_to find_path
  end

  def find_path
    url = Rails.application.routes.recognize_path(request.referrer)
    last_action = url[:action]
    if ['show', 'advanced_mastodon', 'advanced_twitter'].include? last_action
      { action: last_action }
    else
      user_path
    end
  rescue
    user_path
  end

  def mastodon_identifier
  end

  def user_params
    params
      .require(:user)
      .permit(:posting_from_mastodon, :masto_should_post_private,
              :masto_should_post_unlisted, :boost_options,
              :masto_reply_options, :masto_mention_options,
              :posting_from_twitter, :retweet_options, :quote_options,
              :twitter_reply_options, :twitter_content_warning,
              :twitter_original_visibility, :twitter_retweet_visibility,
              :twitter_quote_visibility, :twitter_block_or_allow_list,
              :masto_block_or_allow_list, masto_word_list: [],
                                          twitter_word_list: [])
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
