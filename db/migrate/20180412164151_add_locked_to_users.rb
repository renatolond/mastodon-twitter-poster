class AddLockedToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :locked, :boolean, default: false, null: false
  end
end
