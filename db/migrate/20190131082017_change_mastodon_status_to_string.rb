class ChangeMastodonStatusToString < ActiveRecord::Migration[5.1]
  def change
    change_column :statuses, :masto_id, :string
  end
end
