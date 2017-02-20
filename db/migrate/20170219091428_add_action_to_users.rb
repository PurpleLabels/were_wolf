class AddActionToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :action_type, :integer
  end
end
