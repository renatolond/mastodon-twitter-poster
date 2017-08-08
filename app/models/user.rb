class User < ApplicationRecord
  devise :omniauthable, omniauth_providers: [:twitter, :mastodon]
end
