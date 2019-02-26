class ChangeLastTootToString < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :last_toot, :string
  end
end
