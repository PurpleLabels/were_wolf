class ChangeDatatypeTitleOfUsers < ActiveRecord::Migration[5.0]
  def change
    change_column :users, :is_admin, :boolean,default: false
    change_column :users, :is_dead, :boolean,default: false
    
  end
end
