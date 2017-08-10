class AddBoostOptionsToUsers < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE TYPE boost_options AS ENUM ('MASTO_BOOST_DO_NOT_POST', 'MASTO_BOOST_POST_AS_LINK');
    SQL

    add_column :users, :boost_options, :boost_options, default: 'MASTO_BOOST_DO_NOT_POST'
  end

  def down
    remove_column :users, :boost_options

    execute <<-SQL
      DROP TYPE boost_options;
    SQL
  end
end
