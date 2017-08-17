class AddMastoFixCrossMentionToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :masto_fix_cross_mention, :boolean, default: false
  end
end
