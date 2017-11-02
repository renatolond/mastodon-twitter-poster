class AddRetweetOptionsToUsers < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE retweet_options AS ENUM ('RETWEET_DO_NOT_POST', 'RETWEET_POST_AS_LINK', 'RETWEET_POST_AS_OLD_RT');
    SQL

    add_column :users, :retweet_options, :retweet_options, default: 'RETWEET_DO_NOT_POST'
  end

  def down
    remove_column :users, :retweet_options

    execute <<-SQL
      DROP TYPE retweet_options;
    SQL
  end
end
