class AddDisableToggleToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :posting_from_mastodon, :boolean, default: false
    add_column :users, :posting_from_twitter, :boolean, default: false
  end
end
