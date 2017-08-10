class AddMastoPrivateOptionToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :masto_should_post_private, :boolean, default: false
  end
end
