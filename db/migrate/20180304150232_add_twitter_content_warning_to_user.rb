class AddTwitterContentWarningToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :twitter_content_warning, :string
  end
end
