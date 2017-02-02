class CreateVillages < ActiveRecord::Migration[5.0]
  def change
    create_table :villages do |t|
      t.string :name
      t.string :password

      t.timestamps
    end
  end
end
