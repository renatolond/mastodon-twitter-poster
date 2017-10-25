class CreateStatuses < ActiveRecord::Migration[5.1]
  def change
    create_table :statuses do |t|
      t.references :mastodon_client, foreign_key: true, null: false
      t.bigint :masto_id, null: false
      t.bigint :tweet_id, null: false

      t.timestamps

      t.index [:mastodon_client_id, :masto_id], unique: true
      t.index [:tweet_id], unique: true
    end
  end
end
