class CreateAuthorizations < ActiveRecord::Migration[5.1]
  def change
    create_table :authorizations do |t|
      t.string :provider
      t.string :uid
      t.integer :user_id
      t.string :token
      t.string :secret

      t.timestamps
    end

    add_index :authorizations, [:provider, :uid], unique: true
  end
end
