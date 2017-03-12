class ChangeDatatypeActionType < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :action_type, :string
    change_column :villages, :action_type, :string
    change_column :villages, :action_type, :string
  end
end
