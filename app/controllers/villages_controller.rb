class VillagesController < ApplicationController
  def reload
    @users = User.where(village_id: params[:village_id])
    @village = Village.find(params[:village_id])
    # TODO: YAGUNI
    # @village_settings = VillageSetting.joins(:job)
    #                                  .select('village_settings.*,jobs.*')
    #                                  .where(village_id: params[:village_id])

    action = get_action(@users, @village)
    set_action(@users, @village, action)
    message = get_message(@users, @village, action)
    if action != 'reload'
      ActionCable.server.broadcast "village:#{@village.id}",
                                   count: @users.count,
                                   Action: action,
                                   village_id: @village.id.to_s,
                                   message: message,
                                   user_id: current_user.id
    end
  end

  def start
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
      user.save
      j -= 1
      i += 1 if j.zero?
    end
    Vote.destroy_all('village_id = ' + current_user.village_id.to_s)
    @village_settings = VillageSetting.joins(:job)
                                      .select('village_settings.*,jobs.*')
                                      .where(village_id: params[:format])
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def day
    get_user(params[:format])
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
    current_user.action_type = 'wait'
    current_user.save
    redirect_to action: 'reload', village_id: current_user.village_id
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
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def vote
    @vote = Vote.create
    @vote.village_id = current_user.village_id
    @vote.user_id = current_user.id

    @vote.voted_user = params[:user_id]
    @vote.save

    current_user.action_type = 'wait'
    current_user.save

    redirect_to action: 'reload', village_id: current_user.village_id
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
    redirect_to action: 'reload', village_id: current_user.village_id
  end

  def show
    @village = Village.find(params[:id])
    current_user.village_id = @village.id
    current_user.action_type = 'no_Game'
    current_user.save
    @users = User.where(village_id: params[:id])
    @village_settings = VillageSetting.joins(:job)
                                      .select('village_settings.*,jobs.*')
                                      .where(village_id: params[:id])
                                      .order('job_id asc')
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
    @village.action_type = 'no_Game'
    @village.save

    @jobs = Job.all

    @jobs.each do |job|
      vs = VillageSetting.new(village_id: @village.id, job_id: job.id, num: 0)
      vs.save
    end

    current_user.village_id = @village.id
    current_user.is_admin = true

    current_user.save
    flash[:success] = 'village created!'
    redirect_to action: 'show', id: @village.id
  end

  def search
    @villages = Village.all
    village_id = current_user.village_id

    unless village_id.nil?
      @users = User.where(village_id: village_id)
      if @users.count == 1
        Village.destroy(current_user.village_id)
        current_user.update(village_id: nil, is_admin: false)
        @users.update_all(village_id: nil, is_admin: false)
      else
        if current_user.is_admin
          @remains = User.where('village_id = ' + village_id.to_s + ' and is_admin = false')
          @remains.first.update(is_admin: true)
          @remains.first.save
        end
        current_user.update(village_id: nil, is_admin: false)
        current_user.save

        ActionCable.server.broadcast "village:#{village_id}",
                                     count: @users.count,
                                     village_id: village_id.to_s,
                                     Action: 'reload',
                                     message: '',
                                     user_id: current_user.id
      end
    end
  end

  private

  def get_user(village_id)
    @users = User.where('village_id = ' + village_id)
  end

  def judge(users, village)
    villagerCount = users.where("is_dead = false and job_id <> '1'").count
    wereWolfCount = users.where("is_dead = false and job_id = '1'").count
    if wereWolfCount.zero?
      village.action_type = 'no_Game'
      village.save
      set_user_action(users, 'no_Game')
      return '村人チームの勝利です。'
    elsif villagerCount <= wereWolfCount
      village.action_type = 'no_Game'
      village.save
      set_user_action(users, 'no_Game')
      return '人狼チームの勝利です。'
    else
      return '人狼はまだ潜んでいます。'
    end
  end

  def kill(village_id)
    @votes = Vote.where(village_id: village_id).group(:voted_user).order('count_voted_user desc').count('voted_user').keys
    target_user = User.where('id = ' + @votes[0].to_s)
    target_user[0].is_dead = true
    target_user[0].save
    Vote.destroy_all('village_id = ' + village_id)
    target_user[0].name
  end

  def voteing_result(village_id)
    @votes = Vote.where(village_id: village_id)
                 .group(:voted_user)
                 .order('count_voted_user desc')
                 .count('voted_user').keys
    target_user = User.where('id = ' + @votes[0].to_s)
    target_user[0].is_dead = true
    target_user[0].save
    Vote.destroy_all('village_id = ' + village_id)
    target_user[0].name
  end

  def get_action(users, village)
    wait = 0
    users.each do |user|
      wait += 1 if user.is_dead || user.action_type == 'wait'
    end

    if users.count == wait && village.action_type == 'night'
      'end_Night'
    elsif users.count == wait && village.action_type == 'vote'
      'end_Vote'
    elsif users.count == wait && village.action_type == 'stop'
      'end_Game'
    elsif village.action_type == 'to_Vote'
      'to_Vote'
    elsif village.action_type == 'start'
      'start'
    else
      'reload'
    end
  end

  def get_message(users, village, action)
    message = ''
    case action
    when 'end_Night'
      message = "全員の夜のアクションが終わりました。\n"
      message = message + '昨晩の犠牲者は' + kill(village.id.to_s) + "さんです。\n"
      message += judge(users, village)
    when 'end_Vote'
      message = "全員の投票が終わりました。\n本日の処刑対象は" + voteing_result(village.id.to_s) + "さんです。\n"
      message += judge(users, village)
    when 'end_Game'
      message = 'ゲームを終了します。'
    when 'to_Vote'
      message = '投票の時間です。'
    end
    message
  end

  def set_action(users, village, action)
    case action
    when 'start'
      village.action_type = 'night'
    when 'end_Night'
      village.action_type = 'day'
      set_user_action(users, 'day')
    when 'end_Vote'
      village.action_type = 'night'
      set_user_action(users, 'night')
    when 'end_Game'
      village.action_type = 'no_Game'
      set_user_action(users, 'no_Game')
    when 'to_Vote'
      village.action_type = 'vote'
    end
    village.save
  end

  def set_user_action(users, action)
    users.each do |user|
      user.action_type = action
      user.save
    end
  end
end
