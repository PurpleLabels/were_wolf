class CreateVillageSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :village_settings do |t|
      t.integer :village_id
      t.integer :job_id
      t.integer :num

      t.timestamps
    end
  end
end
