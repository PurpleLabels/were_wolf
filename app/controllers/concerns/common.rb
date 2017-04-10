module Common
  extend ActiveSupport::Concern

  included do
  end

  def enter(village_id)
    current_user.village_id = village_id
    current_user.action_type = 'no_Game'
    current_user.save
  end

  def exit(village_id)
    users = User.where(village_id: village_id)
    if users.count == 1
      Village.destroy(current_user.village_id)
      current_user.update(village_id: nil, is_admin: false)
      users.update_all(village_id: nil, is_admin: false)
    else
      current_user.update(village_id: nil, is_admin: false)
      ActionCable.server.broadcast "village:#{village_id}",
                                   count: users.count,
                                   village_id: village_id.to_s,
                                   Action: 'reload',
                                   message: '',
                                   user_id: current_user.id
    end
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
    if target_user[0].is_protected
      Vote.destroy_all('village_id = ' + village_id)
      'いませんでした。'
    else
      target_user[0].is_dead = true
      target_user[0].save
      Vote.destroy_all('village_id = ' + village_id)
      target_user[0].name + 'さんです。'
    end
  end

  def voting_result(village_id)
    votes = Vote.where(village_id: village_id)
    # .group(:voted_user)
    # .order('count_voted_user desc')
    # .count('voted_user').keys
    message = "\n"
    votes.each do |vote|
      message += User.find(vote.user_id.to_i).name + '→' + User.find(vote.voted_user.to_i).name + "\n"
    end
    votes = votes.group(:voted_user)
                 .order('count_voted_user desc')
                 .count('voted_user')
    if votes[votes.keys[0]] == votes[votes.keys[1]]
      message += "\n" + '投票結果が同数です。再度投票してください。'
    else
      target_user = User.where('id = ' + votes.keys[0].to_s)
      target_user[0].is_dead = true
      target_user[0].save
      message += "\n" + '本日の処刑対象は' + target_user[0].name + 'さんです。'
    end
    Vote.destroy_all('village_id = ' + village_id)
    message
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
      message = message + '昨晩の犠牲者は' + kill(village.id.to_s) + "\n"
      message += judge(users, village)
      users.update(is_protected: false)
    when 'end_Vote'
      message = "全員の投票が終わりました。\n" + voting_result(village.id.to_s) + "\n"
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
    when 'Re_Vote'
      village.action_type = 'to_Vote'
      set_user_action(users, 'vote')
    end
    village.save
  end

  def set_user_action(users, action)
    users.each do |user|
      user.action_type = action
      user.save
    end
  end

  def update_job_number(params)
    @jobs = Job.all
    @jobs.each do |job|
      vs = VillageSetting.where('village_id = ' + params[:id] + ' and job_id =' + job.id.to_s)
      vs.first.update(num: params[:villageSetting][:num][job.id.to_s])
      vs.first.save
    end
  end

  def set_job(village_id)
    village_settings = VillageSetting.where(village_id: params[:format])
                                      .where.not(num: 0).shuffle
    i = 0
    j = 0
    User.where(village_id: village_id).each do |user|
      j = village_settings[i].num if j.zero?
      user.update(job_id: village_settings[i].job_id, action_type: 'night',
                  is_dead: false, is_protected: true)
      j -= 1
      i += 1 if j.zero?
    end
  end

  def reload
    redirect_to controller: 'villages',
                action: 'reload',
                village_id: current_user.village_id
  end

  def night_action(params)
    user_id = params[:user_id]
    if current_user.job_id == 1
      params[:level].to_i.times do
        Vote.create(village_id: current_user.village_id,
                    user_id: current_user.id, voted_user: user_id)
      end
    elsif current_user.job_id == 4
      User.find(user_id).update(is_protected: true)
    end
  end
end
