class VillagesController < ApplicationController
  include Common
  def show
    @village = Village.find(params[:id])
    current_user.update(village_id: params[:id], action_type: 'no_Game')
    @users = User.where(village_id: params[:id])
    #selectが気になる
    @village_settings = VillageSetting.joins(:job)
                                      .select('village_settings.*,jobs.*')
                                      .where(village_id: params[:id])
                                      .order('job_id asc')
  end

  def update
    village = Village.find(params[:id])
    time = params[:village]
    village.update(day_time: time[:day_time],
                   night_time: time[:night_time],
                   vote_time: time[:vote_time])
    update_job_number(params)
    redirect_to action: 'show', id: params.require(:id)
  end

  def new
    @village = Village.new
  end

  def create
    village = Village.create(params.require(:village).permit(:name, :password))
    Job.all.each do |job|
      VillageSetting.create(village_id: village.id, job_id: job.id, num: 0)
    end
    redirect_to action: 'show', id: village.id
  end

  def search
    @villages = Village.all
    exit(current_user.village_id) if current_user.village_id
  end

  def reload
    @users = User.where(village_id: params[:village_id])
    @village = Village.find(params[:village_id])
    if params[:taget] == 'all'
      ActionCable.server.broadcast "village:#{@village.id}",
                                   count: @users.count,
                                   village_id: @village.id.to_s,
                                   message: params[:message],
                                   user_id: current_user.id
    end
  end
end
