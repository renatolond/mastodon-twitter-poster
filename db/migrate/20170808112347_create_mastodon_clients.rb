class CreateMastodonClients < ActiveRecord::Migration[5.1]
  def change
    create_table :mastodon_clients, id: :serial do |t|
      t.string :domain
      t.string :client_id
      t.string :client_secret

      t.timestamps
    end
    add_index :mastodon_clients, :domain, unique: true
  end
end
