class AddNewOptionToQuoteAndRetweet < ActiveRecord::Migration[5.1]
  self.disable_ddl_transaction!
  def up
    execute <<-SQL
      ALTER TYPE retweet_options ADD VALUE 'RETWEET_POST_AS_OLD_RT_WITH_LINK';
    SQL
    execute <<-SQL
      ALTER TYPE quote_options ADD VALUE 'QUOTE_POST_AS_OLD_RT_WITH_LINK';
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
