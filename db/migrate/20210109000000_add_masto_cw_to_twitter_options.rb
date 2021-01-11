class AddMastoCwToTwitterOptions < ActiveRecord::Migration[5.1]
  def change
    execute <<-SQL
      CREATE TYPE masto_cw_options AS ENUM ('CW_AND_CONTENT', 'CONTENT_ONLY', 'CW_ONLY');
    SQL
    add_column :users, :masto_cw_options, :masto_cw_options, null: false, default: "CW_ONLY"
  end
end
