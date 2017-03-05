class VillagesController < ApplicationController
  def reload
    @users = User.where('village_id = ' + params[:village_id].to_s)
    @village = Village.find(params[:village_id])
    @villageSettings = VillageSetting.joins(:job).select('village_settings.*,jobs.*').where('village_id = ' + params[:village_id])
    day = 0
    night = 0
    wait = 0
    vote = 0
    dead = 0
    @users.each do |user|
      if user.is_dead
        dead += 1
      elsif user.action_type == 0
        wait += 1
      elsif user.action_type == 1
        day += 1
      elsif user.action_type == 2
        night += 1
      elsif user.action_type == 3
        vote += 1
      end
    end

    if @village.action_type == 7
      @village.action_type = 2
      @village.save
      ActionCable.server.broadcast "village:#{@village.id}", count: @users.count, Action: 'show', village_id: @village.id.to_s, user_id: current_user.id
    elsif @users.count == wait + dead && @village.action_type == 2
      @votes = Vote.where(village_id: params[:village_id]).group(:voted_user).order('count_voted_user asc').count('voted_user').keys
      # @votes = Vote.where(village_id: params[:village_id]).order('voted_user')
      message = "全員の夜のアクションが終わりました。\n"
      message = message + '昨晩の犠牲者は' + kill(@village.id.to_s) + "さんです。\n"
      message += judge(@village.id.to_s)
      Vote.destroy_all('village_id = ' + current_user.village_id.to_s)
      @users.each do |user|
        user.action_type = 1
        user.save
      end
      @village.action_type = 1
      @village.save

      ActionCable.server.broadcast "village:#{@village.id}", count: @users.count, Action: 'night', village_id: @village.id.to_s, message: message
    elsif @users.count == wait + dead && @village.action_type == 3
      @users.each do |user|
        user.action_type = 2
        user.save
      end
      @village.action_type = 2
      @village.save
      message = "全員の投票が終わりました。\n本日の処刑対象は" + voteingResult(@village.id.to_s) + "さんです。\n"
      message += judge(@village.id.to_s)
      ActionCable.server.broadcast "village:#{@village.id}", count: @users.count, Action: 'night', village_id: @village.id.to_s, message: message, user_id: current_user.id
    elsif @users.count == wait + dead && @village.action_type == 5
      @village.action_type = 0
      @village.save
      message = 'ゲームを終了します。'
      ActionCable.server.broadcast "village:#{@village.id}", count: @users.count, Action: 'stop', village_id: @village.id.to_s, message: message, user_id: current_user.id
    elsif @village.action_type == 6
      @village.action_type = 3
      @village.save
      ActionCable.server.broadcast "village:#{@village.id}", count: @users.count, Action: 'to_vote', village_id: @village.id.to_s, message: message, user_id: current_user.id
    end
  end

  def start
    @villageSettings = VillageSetting.where('village_id = ' + params[:format] + ' and num <> 0')
    @villageSettings = @villageSettings.shuffle
    @village = Village.find(params[:format])
    @village.action_type = 7
    @village.save
    @users = User.where('village_id = ' + params[:format])
    i = 0
    j = 0
    @users.each do |user|
      j = @villageSettings[i].num if j == 0
      user.job_id = @villageSettings[i].job_id
      user.action_type = 2
      user.is_dead = false
      user.save
      j -= 1
      i += 1 if j == 0
    end
    Vote.destroy_all('village_id = ' + current_user.village_id.to_s)
    @villageSettings = VillageSetting.joins(:job).select('village_settings.*,jobs.*').where('village_id = ' + params[:format])

    # ActionCable.server.broadcast "village:#{params[:format]}",village_id:params[:format]
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def day
    getUser(params[:format])
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
    end
    current_user.action_type = 0
    current_user.save
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def to_vote
    @users = User.where('village_id = ' + params[:village_id])
    @users.each do |user|
      user.action_type = 3
      user.save
    end
    @village = Village.find(params[:village_id])
    @village.action_type = 6
    @village.save
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def vote
    @vote = Vote.create
    @vote.village_id = current_user.village_id
    @vote.user_id = current_user.id

    @vote.voted_user = params[:user_id]
    @vote.save

    current_user.action_type = 0
    current_user.save

    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def stop
    @users = User.where('village_id = ' + params[:format])
    @village = Village.find(params[:format])
    @village.action_type = 5
    @village.save
    @villageSettings = VillageSetting.joins(:job).select('village_settings.*,jobs.*').where('village_id = ' + params[:format])
    @users.each do |user|
      user.job_id = 1
      user.action_type = 0
      user.save
    end
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def show
    @village = Village.find(params[:id])
    @user = User.find(current_user.id)
    @user.village_id = @village.id
    @user.action_type = 0
    @user.save
    @users = User.where('village_id = ' + params[:id])
    # @villageSettings = VillageSetting.joins("INNER JOIN jobs ON village_settings.job_id = jobs.id").select('village_settings.*,jobs.*').where("village_id = "+params[:id] )
    @villageSettings = VillageSetting.joins(:job).select('village_settings.*,jobs.*').where('village_id = ' + params[:id])
  end

  def update
    @village = Village.find(params[:id])
    @village.day_time = params[:village][:day_time]
    @village.night_time = params[:village][:night_time]
    @village.vote_time = params[:village][:vote_time]
    @village.save

    @jobs = Job.all
    @jobs.each do |job|
      vs = VillageSetting.where('village_id = ' + @village.id.to_s + ' and job_id =' + job.id.to_s)
      vs.first.num = params[:villageSetting][:num][job.id.to_s]
      vs.first.save
    end
    redirect_to action: 'show', id: params.require(:id)
  end

  def new
    @village = Village.new if signed_in?
  end

  def create
    village = params.require(:village).permit(:name, :password)

    @village = Village.create(village)
    @village.is_played = false
    @village.day_time = 2
    @village.night_time = 60
    @village.vote_time = 20
    @village.action_type = 0
    @village.save

    @jobs = Job.all

    @jobs.each do |job|
      vs = VillageSetting.new(village_id: @village.id, job_id: job.id, num: 0)
      vs.save
    end

    @user = User.find(current_user.id)
    @user.village_id = @village.id
    @user.is_admin = true

    @user.save
    flash[:success] = 'village created!'
    redirect_to action: 'show', id: @village.id
  end

  def search
    @villages = Village.all
    @user = User.find(current_user.id)
    @village_id = @user.village_id

    unless @village_id.nil?
      @users = User.where('village_id = ' + @village_id.to_s)
      if @users.count == 1
        Village.destroy(@user.village_id)
        @users.update_all(village_id: nil, is_admin: false)

      else
        if @user.is_admin
          @remains = User.where('village_id = ' + @village_id.to_s + ' and is_admin = false')
          @remains.first.update(is_admin: true)
          @remains.first.save
        end
        @user.update(village_id: nil, is_admin: false)
        @user.save
        # @rr = ApplicationController.renderer.render(@users)
        ActionCable.server.broadcast "village:#{@village_id}", count: @users.count, village_id: @village_id.to_s, Action: 'show', user_id: current_user.id
      end
    end
  end

  private

  def getUser(village_id)
    @users = User.where('village_id = ' + village_id)
  end

  private

  def judge(village_id)
    @users = User.where('village_id = ' + village_id)
    villagerCount = @users.where("is_dead = false and job_id <> '1'").count
    wereWolfCount = @users.where("is_dead = false and job_id = '1'").count
    if wereWolfCount == 0
      return '村人チームの勝利です。'
    elsif villagerCount <= wereWolfCount
      return '人狼チームの勝利です。'
    else
      return '人狼はまだ潜んでいます。'
    end
  end

  private

  def kill(village_id)
    @votes = Vote.where(village_id: village_id).group(:voted_user).order('count_voted_user desc').count('voted_user').keys
    target_user = User.where('id = ' + @votes[0].to_s)
    target_user[0].is_dead = true
    target_user[0].save
    Vote.destroy_all('village_id = ' + village_id)
    target_user[0].name
  end

  private

  def voteingResult(village_id)
    @votes = Vote.where(village_id: village_id).group(:voted_user).order('count_voted_user desc').count('voted_user').keys
    target_user = User.where('id = ' + @votes[0].to_s)
    target_user[0].is_dead = true
    target_user[0].save
    Vote.destroy_all('village_id = ' + village_id)
    target_user[0].name
  end
end
