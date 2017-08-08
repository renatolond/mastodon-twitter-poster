class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations

  def twitter
    @twitter ||= authorizations.where(provider: :twitter).last
  end

  def mastodon
    @mastodon ||= authorizations.where(provider: :mastodon).last
  end

  class << self
    def from_omniauth(auth, current_user)
      authorization = Authorization.where(provider: auth.provider, uid: auth.uid.to_s).first_or_initialize(provider: auth.provider, uid: auth.uid.to_s)
      user = current_user || authorization.user || User.new
      authorization.user   = user
      authorization.token  = auth.credentials.token
      authorization.secret = auth.credentials.secret

      authorization.save
      authorization.user
    end
  end
end
