class AddDetailsToVillages < ActiveRecord::Migration[5.0]
  def change
    add_column :villages, :is_played, :boolean
    add_column :villages, :day_time, :integer
    add_column :villages, :night_time, :integer
    add_column :villages, :vote_time, :integer
  end
end
