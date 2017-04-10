class VotesController < ApplicationController
  def new
    byebug
    users = User.where(village_id: params[:village_id])
    users.update_all(action_type: 'vote')
    village = Village.find(params[:village_id])
    village.update(action_type: 'to_Vote')
    redirect_to controller: 'villages',
                action: 'reload',
                village_id: current_user.village_id
  end

  def create
    Vote.create(village_id: current_user.village_id,
                user_id: current_user.id,
                voted_user: params[:user_id])
    current_user.update(action_type: 'wait')
    redirect_to controller: 'villages',
                action: 'reload',
                village_id: current_user.village_id
  end
end
