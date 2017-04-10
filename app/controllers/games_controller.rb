class GamesController < ApplicationController
  include Common
  def new
    Village.find(params[:format]).update(action_type: 'start')
    set_job(params[:format])
    Vote.destroy_all(village_id: current_user.village_id)
    reload
  end

  def night
    night_action(params)
    current_user.update(action_type: 'wait')
    reload
  end

  def stop
    User.where(village_id: params[:format]).update_all(action_type: 'wait')
    Village.find(params[:format]).update(action_type: 'stop')
    reload
  end

  def to_vote
    User.where(village_id: params[:village_id]).update_all(action_type: 'vote')
    Village.find(params[:village_id]).update(action_type: 'to_Vote')
    reload
  end

  def vote
    Vote.create(village_id: current_user.village_id,
                user_id: current_user.id,
                voted_user: params[:user_id])
    current_user.update(action_type: 'wait')
    reload
  end
end
