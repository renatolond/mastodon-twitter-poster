class Authorization < ApplicationRecord
  belongs_to :user, inverse_of: :authorizations, required: true
  belongs_to :mastodon_client, required: false

  default_scope { order("id asc") }
end
