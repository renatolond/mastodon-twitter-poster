class ChangeDefaultsForBetterOnes < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :twitter_retweet_visibility, :masto_visibility, default: 'MASTO_UNLISTED'
    change_column :users, :twitter_quote_visibility, :masto_visibility, default: 'MASTO_UNLISTED'
    change_column :users, :quote_options, :quote_options, default: 'QUOTE_POST_AS_OLD_RT_WITH_LINK'
    change_column :users, :retweet_options, :retweet_options, default: 'RETWEET_POST_AS_OLD_RT_WITH_LINK'
    change_column :users, :twitter_reply_options, :twitter_reply_options, default: 'TWITTER_REPLY_POST_SELF'
    change_column :users, :masto_reply_options, :masto_reply_options, default: 'MASTO_REPLY_POST_SELF'
  end
end
