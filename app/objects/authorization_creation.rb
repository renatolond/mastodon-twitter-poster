class AuthorizationCreation
  attr_accessor :authorization
  def initialize(authorization)
    @authorization = authorization
  end

  def save
    add_mastodon_client

    @authorization.save

    fetch_profile_data

    @authorization.save
  end

  def add_mastodon_client
    if @authorization.provider == 'mastodon' && @authorization.new_record?
      @authorization.mastodon_client = MastodonClient.find_by_domain(mastodon_domain)
      Rails.logger.error { "Could not find MastodonClient for #{uid}" } if @authorization.mastodon_client.nil?
    end
  end

  def fetch_profile_data
    return unless @authorization.saved_change_to_token?

    if @authorization.provider == 'twitter'
      @authorization.user.save_last_tweet_id
    elsif @authorization.provider == 'mastodon'
      @authorization.user.save_last_toot_id
    end
  end

  def mastodon_domain
    @authorization.uid.split('@').last
  end
end
