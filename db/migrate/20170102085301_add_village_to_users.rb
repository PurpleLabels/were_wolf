class AddVillageToUsers < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :village_id, :integer
    add_column :users, :job_id, :integer
    add_column :users, :is_admin, :boolean
    add_column :users, :is_dead, :boolean
  end
end
