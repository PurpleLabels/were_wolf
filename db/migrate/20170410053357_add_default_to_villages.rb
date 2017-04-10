class AddDefaultToVillages < ActiveRecord::Migration[5.0]
  def change
    change_column :villages, :is_played, :boolean,default: false
    change_column :villages, :day_time,:integer, default: 2
    change_column :villages, :night_time,:integer, default: 60
    change_column :villages, :vote_time,:integer, default: 20
    change_column :villages, :action_type,:string, default: 'no_Game'
  end
end
