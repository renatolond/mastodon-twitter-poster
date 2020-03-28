class AddMastodonUserIdToAuthorization < ActiveRecord::Migration[5.2]
  def change
    add_column :authorizations, :mastodon_user_id, :string
  end
end
