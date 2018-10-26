class HomeController < ApplicationController
  def index
    if current_user
      @uid = current_user.mastodon&.uid
      @handle = current_user.twitter_handle
    end
  end
end
