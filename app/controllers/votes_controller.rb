class VotesController < ApplicationController
  def new
    @users = User.where(village_id: params[:village_id])
    @users.each do |user|
      user.action_type = 'vote'
      user.save
    end
    @village = Village.find(params[:village_id])
    @village.action_type = 'to_Vote'
    @village.save
    redirect_to controller: 'villages', action: 'reload', village_id: current_user.village_id
  end

  def create
    @vote = Vote.create
    @vote.village_id = current_user.village_id
    @vote.user_id = current_user.id

    @vote.voted_user = params[:user_id]
    @vote.save

    current_user.action_type = 'wait'
    current_user.save

    redirect_to controller: 'villages', action: 'reload', village_id: current_user.village_id
  end
end
