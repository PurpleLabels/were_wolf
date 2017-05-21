class VillagesController < ApplicationController
  include Common
  def show
    @village = Village.find(params[:id])
    current_user.update(village_id: params[:id],
                        action_type: 'no_Game', job_id: 2)
    @users = User.where(village_id: params[:id])
    # selectが気になる
    @village_settings = VillageSetting.joins(:job)
                                      .select('village_settings.*,jobs.*')
                                      .where(village_id: params[:id])
                                      .order('job_id asc')
  end

  def update
    update_job_number(params)
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
    @users = User.where(village_id: params[:village_id]).order('seq_no asc')
    @village = Village.find(params[:village_id])
    @tweet = Message.where(village_id: params[:village_id], message_type: 'tweet').order('updated_at desc')[0]
    if params[:taget] == 'all'
      ActionCable.server.broadcast "village:#{@village.id}",
                                   count: @users.count,
                                   village_id: @village.id.to_s,
                                   message: params[:message],
                                   user_id: current_user.id
    end
  end
end
