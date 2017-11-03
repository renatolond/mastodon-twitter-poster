class AddQuoteOptionsToUsers < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE quote_options AS ENUM ('QUOTE_DO_NOT_POST', 'QUOTE_POST_AS_LINK', 'QUOTE_POST_AS_OLD_RT');
    SQL

    add_column :users, :quote_options, :quote_options, default: 'QUOTE_POST_AS_LINK'
  end

  def down
    remove_column :users, :quote_options

    execute <<-SQL
      DROP TYPE quote_options;
    SQL
  end
end
