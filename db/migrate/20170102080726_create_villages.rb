class CreateVillages < ActiveRecord::Migration[5.0]
  def change
    drop_table :villages
    create_table :villages do |t|
      t.string :name
      t.string :password

      t.timestamps
    end
  end
end
