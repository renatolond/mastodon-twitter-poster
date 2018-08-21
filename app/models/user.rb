class User < ApplicationRecord
  enum boost_options: {
    masto_boost_do_not_post: 'MASTO_BOOST_DO_NOT_POST',
    masto_boost_post_as_link: 'MASTO_BOOST_POST_AS_LINK'
  }

  enum masto_reply_options: {
    masto_reply_do_not_post: 'MASTO_REPLY_DO_NOT_POST',
    masto_reply_post_self: 'MASTO_REPLY_POST_SELF'
  }

  enum twitter_reply_options: {
    twitter_reply_do_not_post: 'TWITTER_REPLY_DO_NOT_POST',
    twitter_reply_post_self: 'TWITTER_REPLY_POST_SELF'
  }

  enum masto_mention_options: {
    masto_mention_do_not_post: 'MASTO_MENTION_DO_NOT_POST'
  }

  enum retweet_options: {
    retweet_do_not_post: 'RETWEET_DO_NOT_POST',
    retweet_post_as_old_rt: 'RETWEET_POST_AS_OLD_RT',
    retweet_post_as_old_rt_with_link: 'RETWEET_POST_AS_OLD_RT_WITH_LINK'
  }

  enum quote_options: {
    quote_do_not_post: 'QUOTE_DO_NOT_POST',
    quote_post_as_old_rt: 'QUOTE_POST_AS_OLD_RT',
    quote_post_as_old_rt_with_link: 'QUOTE_POST_AS_OLD_RT_WITH_LINK'
  }

  masto_visibility = {
    public: 'MASTO_PUBLIC',
    unlisted: 'MASTO_UNLISTED',
    private: 'MASTO_PRIVATE'
  }.freeze
  enum twitter_original_visibility: masto_visibility, _prefix: true
  enum twitter_retweet_visibility: masto_visibility, _prefix: true
  enum twitter_quote_visibility: masto_visibility, _prefix: true

  before_validation :strip_whitespace

  def strip_whitespace
    self.twitter_content_warning = self.twitter_content_warning.strip if self.twitter_content_warning.respond_to?(:strip)
    self.twitter_content_warning = nil if self.twitter_content_warning.blank?
  end

  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  def twitter
    @twitter ||= authorizations.where(provider: :twitter).last
  end

  def mastodon
    @mastodon ||= authorizations.where(provider: :mastodon).last
  end

  def save_last_tweet_id
    last_status = twitter_client.user_timeline(count: 1).first
    self.last_tweet = last_status.id unless last_status.nil?
    self.save
  end

  def save_last_toot_id
    last_status = mastodon_client.statuses(mastodon_id, limit: 1).first
    self.last_toot = last_status.id unless last_status.nil?
    self.save
  end

  def self.twitter_client_secret
    ENV['TWITTER_CLIENT_SECRET']
  end

  def self.twitter_client_id
    ENV['TWITTER_CLIENT_ID']
  end

  def twitter_client
    @twitter_client ||= Twitter::REST::Client.new do |config|
      config.consumer_key = self.class.twitter_client_id
      config.consumer_secret = self.class.twitter_client_secret
      config.access_token = twitter.try(:token)
      config.access_token_secret = twitter.try(:secret)
    end
  end

  def mastodon_id
    @mastodon_id ||= mastodon_client.verify_credentials.id
  end

  def mastodon_domain
    @mastodon_domain ||= "https://#{mastodon.mastodon_client.domain}"
  end

  def mastodon_client
    @mastodon_client ||= Mastodon::REST::Client.new(base_url: mastodon_domain, bearer_token: mastodon.token)
  end

  def twitter_using_blocklist
    twitter_block_or_allow_list == 'BLOCK_WITH_WORDS'
  end

  def twitter_using_allowlist
    twitter_block_or_allow_list == 'ALLOW_WITH_WORDS'
  end

  def masto_using_blocklist
    masto_block_or_allow_list == 'BLOCK_WITH_WORDS'
  end

  def masto_using_allowlist
    masto_block_or_allow_list == 'ALLOW_WITH_WORDS'
  end

  def self.do_not_allow_users
    ENV['DO_NOT_ALLOW_NEW_USERS']
  end

  def self.get_authorization(provider, uid)
    if(do_not_allow_users)
      Authorization.where(provider: provider, uid: uid).first
    else
      Authorization.where(provider: provider, uid: uid).first_or_initialize(provider: provider, uid: uid)
    end
  end

  BLOCKED_UIDS = ['example@bad.bad.server']

  def self.from_omniauth(auth, current_user)
    authorization = get_authorization(auth.provider, auth.uid.to_s) unless BLOCKED_UIDS.include? auth.uid.to_s
    return authorization if authorization.nil?

    user = current_user || authorization.user || User.new
    authorization.user   = user
    authorization.token  = auth.credentials.token
    authorization.secret = auth.credentials.secret
    auth_creation = AuthorizationCreation.new(authorization)
    auth_creation.save

    authorization.user
  end
end
