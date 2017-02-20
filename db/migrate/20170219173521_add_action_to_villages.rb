class AddActionToVillages < ActiveRecord::Migration[5.0]
  def change
    add_column :villages, :action_type, :integer
  end
end
