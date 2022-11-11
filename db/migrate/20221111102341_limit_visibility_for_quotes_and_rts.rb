class LimitVisibilityForQuotesAndRts < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      CREATE TYPE masto_limited_visibility AS ENUM ('MASTO_UNLISTED', 'MASTO_PRIVATE');
      UPDATE users set twitter_retweet_visibility = 'MASTO_UNLISTED' WHERE twitter_retweet_visibility is NULL or twitter_retweet_visibility = 'MASTO_PUBLIC';
      UPDATE users set twitter_quote_visibility = 'MASTO_UNLISTED' WHERE twitter_quote_visibility is NULL or twitter_quote_visibility = 'MASTO_PUBLIC';

      ALTER TABLE users
      ALTER COLUMN twitter_retweet_visibility SET DEFAULT NULL,
      ALTER COLUMN twitter_quote_visibility SET DEFAULT NULL;

      ALTER TABLE users
      ALTER COLUMN twitter_retweet_visibility SET NOT NULL,
      ALTER COLUMN twitter_retweet_visibility SET DEFAULT 'MASTO_UNLISTED'::masto_limited_visibility,
      ALTER COLUMN twitter_retweet_visibility TYPE masto_limited_visibility USING twitter_retweet_visibility::varchar::masto_limited_visibility;

      ALTER TABLE users
      ALTER COLUMN twitter_quote_visibility SET NOT NULL,
      ALTER COLUMN twitter_quote_visibility SET DEFAULT 'MASTO_UNLISTED'::masto_limited_visibility,
      ALTER COLUMN twitter_quote_visibility TYPE masto_limited_visibility USING twitter_quote_visibility::varchar::masto_limited_visibility;
    SQL
    change_column :users, :twitter_quote_visibility, :masto_limited_visibility, null: false
  end
end
