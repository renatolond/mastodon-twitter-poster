class AddMastoUnlistedOptionToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :masto_should_post_unlisted, :boolean, default: false
  end
end
