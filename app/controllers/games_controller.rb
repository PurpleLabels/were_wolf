class GamesController < ApplicationController
  def new
    @village_settings = VillageSetting.where('village_id = ' + params[:format] + ' and num <> 0')
    @village_settings = @village_settings.shuffle
    @village = Village.find(params[:format])
    @village.action_type = 'start'
    @village.save
    @users = User.where(village_id: params[:format])
    i = 0
    j = 0
    @users.each do |user|
      j = @village_settings[i].num if j.zero?
      user.job_id = @village_settings[i].job_id
      user.action_type = 'night'
      user.is_dead = false
      user.is_protected = true
      user.save
      j -= 1
      i += 1 if j.zero?
    end
    Vote.destroy_all('village_id = ' + current_user.village_id.to_s)
    @village_settings = VillageSetting.joins(:job)
                                      .select('village_settings.*,jobs.*')
                                      .where(village_id: params[:format])
    redirect_to controller: 'villages', action: 'reload', village_id: current_user.village_id
  end

  def night
    # 人狼の場合
    if current_user.job_id == 1
      num = 0
      level = params[:level].to_i
      while num < level
        print('num = ', num)
        num += 1
        @vote = Vote.create
        @vote.village_id = current_user.village_id
        @vote.user_id = current_user.id
        @vote.voted_user = params[:user_id]
        @vote.save
      end
    elsif current_user.job_id == 4
      User.find(params[:user_id]).update(is_protected:true)
    end

    current_user.action_type = 'wait'
    current_user.save
    redirect_to controller: 'villages', action: 'reload', village_id: current_user.village_id
  end

  def stop
    @users = User.where(village_id: params[:format])
    @village = Village.find(params[:format])
    @village.action_type = 'stop'
    @village.save
    @village_settings = VillageSetting.joins(:job)
                                      .select('village_settings.*,jobs.*')
                                      .where(village_id: params[:format])
    @users.each do |user|
      user.job_id = 1
      user.action_type = 'wait'
      user.save
    end
    redirect_to controller: 'villages', action: 'reload', village_id: current_user.village_id
  end

  def to_vote
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

  def vote
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
