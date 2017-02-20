class CreateVotes < ActiveRecord::Migration[5.0]
  def change
    create_table :votes do |t|
      t.integer :village_id
      t.integer :user_id
      t.integer :voted_user

      t.timestamps
    end
  end
end
