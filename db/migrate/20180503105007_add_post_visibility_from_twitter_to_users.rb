class AddPostVisibilityFromTwitterToUsers < ActiveRecord::Migration[5.1]
  def change
    execute <<-SQL
      CREATE TYPE masto_visibility AS ENUM ('MASTO_PUBLIC', 'MASTO_UNLISTED', 'MASTO_PRIVATE');
    SQL
    add_column :users, :twitter_original_visibility, :masto_visibility
    add_column :users, :twitter_retweet_visibility, :masto_visibility
    add_column :users, :twitter_quote_visibility, :masto_visibility
  end
end
