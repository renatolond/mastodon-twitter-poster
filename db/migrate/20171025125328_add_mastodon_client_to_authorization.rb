class AddMastodonClientToAuthorization < ActiveRecord::Migration[5.1]
  def change
    add_reference :authorizations, :mastodon_client, foreign_key: true
  end
end
