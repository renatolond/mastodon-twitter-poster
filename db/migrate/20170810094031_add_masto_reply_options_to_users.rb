class AddMastoReplyOptionsToUsers < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE masto_reply_options AS ENUM ('MASTO_REPLY_DO_NOT_POST');
    SQL

    add_column :users, :masto_reply_options, :masto_reply_options, default: 'MASTO_REPLY_DO_NOT_POST'
  end

  def down
    remove_column :users, :masto_reply_options

    execute <<-SQL
      DROP TYPE masto_reply_options;
    SQL
  end
end
