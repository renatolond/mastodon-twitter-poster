class HomeController < ApplicationController
  def index
    if current_user
      @uid = current_user.mastodon&.uid
      @domain = current_user.mastodon_client&.base_url
      @handle = current_user.twitter_handle
      # TODO: Merge this Stoplight with the one in MastodonUserProcessor to avoid different params
      @stoplight_domain_status = Stoplight("source:#{current_user.mastodon_domain}").with_threshold(3).with_cool_off_time(5.minutes.seconds).color if current_user.mastodon
    end
  end

  def privacy; end
end
