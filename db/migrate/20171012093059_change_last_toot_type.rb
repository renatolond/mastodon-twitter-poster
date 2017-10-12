class ChangeLastTootType < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :last_toot, :bigint
  end
end
