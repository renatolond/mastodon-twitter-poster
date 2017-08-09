class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  def twitter
    @twitter ||= authorizations.where(provider: :twitter).last
  end

  def mastodon
    @mastodon ||= authorizations.where(provider: :mastodon).last
  end

  def save_last_tweet_id
    return unless self.last_tweet.nil?

    last_status = twitter_client.user_timeline(count: 1).first
    self.last_tweet = last_status.id unless last_status.nil?
    self.save
  end

  def save_last_toot_id
    return unless self.last_toot.nil?
    last_status = mastodon_client.statuses(mastodon_id, limit: 1).first
    self.last_toot = last_status.id unless last_status.nil?
    self.save
  end

  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key = ENV['TWITTER_CLIENT_ID']
      config.consumer_secret = ENV['TWITTER_CLIENT_SECRET']
      config.access_token = twitter.try(:token)
      config.access_token_secret = twitter.try(:secret)
    end
  end

  def mastodon_id
    @mastodon_id ||= mastodon_client.verify_credentials.id
  end

  def mastodon_domain
    @mastodon_domain ||= "https://#{mastodon.uid.split('@').last}"
  end

  def mastodon_client
    @mastodon_client ||= Mastodon::REST::Client.new(base_url: mastodon_domain, bearer_token: mastodon.token)
  end

  class << self
    def from_omniauth(auth, current_user)
      authorization = Authorization.where(provider: auth.provider, uid: auth.uid.to_s).first_or_initialize(provider: auth.provider, uid: auth.uid.to_s)
      user = current_user || authorization.user || User.new
      authorization.user   = user
      authorization.token  = auth.credentials.token
      authorization.secret = auth.credentials.secret

      authorization.save

      if auth.provider == 'twitter'
        authorization.user.save_last_tweet_id
      elsif auth.provider == 'mastodon'
        authorization.user.save_last_toot_id
      end

      authorization.user
    end
  end
end
