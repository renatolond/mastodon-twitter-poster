class AddWordListToUser < ActiveRecord::Migration[5.1]
  def change
    reversible do |m|
      m.up {
        execute <<-SQL
      CREATE TYPE block_or_allow AS ENUM ('BLOCK_WITH_WORDS', 'ALLOW_WITH_WORDS');
        SQL
      }
      m.down {
        execute <<-SQL
        DROP TYPE block_or_allow;
        SQL
      }
    end

    add_column :users, :twitter_word_list, :string, array: true, default: []
    add_column :users, :twitter_block_or_allow_list, :block_or_allow
    add_column :users, :masto_word_list, :string, array: true, default: []
    add_column :users, :masto_block_or_allow_list, :block_or_allow
  end
end
