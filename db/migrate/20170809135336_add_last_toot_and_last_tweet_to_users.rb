class AddLastTootAndLastTweetToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_toot, :integer
    add_column :users, :last_tweet, :bigint
  end
end
