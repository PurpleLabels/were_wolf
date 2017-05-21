class RenameOrderColumnToUsers < ActiveRecord::Migration[5.0]
  def change
    rename_column :users, :order, :seq_no
  end
end
