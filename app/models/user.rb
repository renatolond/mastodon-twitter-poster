class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]

  has_many :authorizations
end
