class RemovePostAsLink < ActiveRecord::Migration[5.1]
  def up
    execute "UPDATE users SET quote_options='QUOTE_POST_AS_OLD_RT_WITH_LINK'  where quote_options = 'QUOTE_POST_AS_LINK';"
    execute "UPDATE users SET retweet_options='RETWEET_POST_AS_OLD_RT_WITH_LINK'  where retweet_options = 'RETWEET_POST_AS_LINK';"
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
