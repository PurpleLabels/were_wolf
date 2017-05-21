class AddDetailsToMessages < ActiveRecord::Migration[5.0]
  def change
    add_column :messages, :village_id, :integer
  end
end
