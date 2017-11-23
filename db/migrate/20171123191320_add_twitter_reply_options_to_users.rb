class AddTwitterReplyOptionsToUsers < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE twitter_reply_options AS ENUM ('TWITTER_REPLY_DO_NOT_POST', 'TWITTER_REPLY_POST_SELF');
    SQL

    add_column :users, :twitter_reply_options, :twitter_reply_options, default: 'TWITTER_REPLY_DO_NOT_POST'
  end

  def down
    remove_column :users, :twitter_reply_options

    execute <<-SQL
      DROP TYPE twitter_reply_options;
    SQL
  end
end
