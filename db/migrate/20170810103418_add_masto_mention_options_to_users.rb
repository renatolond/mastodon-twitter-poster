class AddMastoMentionOptionsToUsers < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE masto_mention_options AS ENUM ('MASTO_MENTION_DO_NOT_POST');
    SQL

    add_column :users, :masto_mention_options, :masto_mention_options, default: 'MASTO_MENTION_DO_NOT_POST'
  end

  def down
    remove_column :users, :masto_mention_options

    execute <<-SQL
      DROP TYPE masto_mention_options;
    SQL
  end
end
