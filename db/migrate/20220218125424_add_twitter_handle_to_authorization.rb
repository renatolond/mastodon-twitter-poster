class AddTwitterHandleToAuthorization < ActiveRecord::Migration[7.0]
  def change
    add_column :authorizations, :twitter_handle, :string, null: true, default: nil
  end
end
