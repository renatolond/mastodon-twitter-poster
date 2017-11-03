class ChangeQuoteOptionsDefault < ActiveRecord::Migration[5.1]
  def change
    change_column :users, :quote_options, :quote_options, default: 'QUOTE_DO_NOT_POST'
  end
end
