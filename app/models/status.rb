class Status < ApplicationRecord
  belongs_to :mastodon_client, required: true
end
