class AddTwitterLastCheckedAndMastodonLastCheckToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :twitter_last_check, :timestamp, default: -> { 'CURRENT_TIMESTAMP' }
    add_column :users, :mastodon_last_check, :timestamp, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
