class AddReplyOptionToReplyEnum < ActiveRecord::Migration[5.1]
  self.disable_ddl_transaction!
  def change
    execute <<-SQL
      ALTER TYPE masto_reply_options ADD VALUE 'MASTO_REPLY_POST_SELF';
    SQL
  end
end
