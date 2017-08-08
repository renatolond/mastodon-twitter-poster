class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  class << self
    def from_omniauth(auth, current_user)
      authorization = Authorization.where(provider: auth.provider, uid: auth.uid.to_s).first_or_initialize(provider: auth.provider, uid: auth.uid.to_s)
      user = current_user || authorization.user || User.new
      authorization.user   = user
      authorization.token  = auth.credentials.token
      authorization.secret = auth.credentials.secret

      if auth.provider == 'twitter'
        authorization.profile_url  = auth.info.urls['Twitter']
        authorization.display_name = auth.info.nickname
      elsif auth.provider == 'mastodon'
        authorization.profile_url  = auth.info.urls['Profile']
        authorization.display_name = auth.info.nickname
      end

      authorization.save
      authorization.user
    end
  end
end
