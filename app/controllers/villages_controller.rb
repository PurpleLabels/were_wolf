class VillagesController < ApplicationController
  include Common
  def show
    @village = Village.find(params[:id])
    enter(@village.id)
    @users = User.where(village_id: params[:id])
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
    exit(current_user.village_id) unless current_user.village_id.nil?
  end

  def reload
    @users = User.where(village_id: params[:village_id])
    @village = Village.find(params[:village_id])
    # TODO: YAGUNI
    # @village_settings = VillageSetting.joins(:job)
    #                                  .select('village_settings.*,jobs.*')
    #                                  .where(village_id: params[:village_id])
    action = get_action(@users, @village)
    number_allive = @users.where(is_dead: false).count
    message = get_message(@users, @village, action)

    if action == 'end_Vote' && @users.where(is_dead: false).count == number_allive
      action = 'Re_Vote'
    end
    set_action(@users, @village, action)
    if action != 'reload'
      ActionCable.server.broadcast "village:#{@village.id}",
                                   count: @users.count,
                                   Action: action,
                                   village_id: @village.id.to_s,
                                   message: message,
                                   user_id: current_user.id
    end
  end
end
