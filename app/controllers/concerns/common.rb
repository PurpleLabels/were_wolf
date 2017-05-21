module Common
  extend ActiveSupport::Concern

  included do
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

  def update_action_type(action_type)
    User.where(village_id: current_user.village_id).where.not(action_type: 'no_game')
        .update_all(action_type: action_type)
    Village.where(id: current_user.village_id).where.not(action_type: 'no_game').update(action_type: action_type)
  end

  def update_action_type_on_start(action_type)
    User.where(village_id: current_user.village_id)
        .update_all(action_type: action_type)
    Village.find(current_user.village_id).update(action_type: action_type)
  end

  def get_night_message
    message = "全員の夜のアクションが終わりました。\n" \
              '昨晩の犠牲者は' + kill(current_user.village_id) + "\n" +
              judge
  end

  def bite(village_id)
    fottune_teller = User.where(village_id: village_id, job_id: 3)
    votes = Vote.where(village_id: village_id).where.not(user_id: fottune_teller.ids).group(:voted_user)
                .order('count_voted_user desc').count('voted_user').keys
    return nil if votes.count == 0
    target_user = User.find(votes[0])
    Vote.where(village_id: village_id).where.not(user_id: fottune_teller.ids).destroy_all(village_id: village_id)
    if target_user.is_protected || target_user.job_id == 9
      nil
    else
      target_user.update(is_dead: true)
      target_user.name + 'さん'
    end
  end

  def curse(village_id)
    fottune_teller = User.where(village_id: village_id, job_id: 3)
    votes = Vote.where(village_id: village_id, user_id: fottune_teller.ids).group(:voted_user)
                .order('count_voted_user desc').count('voted_user').keys
    return nil if votes.count == 0
    target_user = User.find(votes[0])
    Vote.where(village_id: village_id, user_id: fottune_teller.ids).destroy_all(village_id: village_id)
    if target_user.job_id == 9
      target_user.update(is_dead: true)
      target_user.name + 'さん'
    end
  end

  def kill(village_id)
    killed_player = [bite(village_id), curse(village_id)].compact
    if killed_player[0].nil?
      'いませんでした。'
    elsif killed_player.size == 2
      killed_player[0] + '、' + killed_player[1] + 'です。'
    else
      killed_player[0] + 'です。'
    end
  end

  def judge
    users = User.where(village_id: current_user.village_id)
    village = Village.find(current_user.village_id)
    villager_count = users.where(is_dead: false).where.not(job_id: [1, 9]).count
    werewolf_count = users.where(is_dead: false, job_id: 1).count
    fox_count = users.where(is_dead: false, job_id: 9).count
    if werewolf_count.zero? && fox_count.zero?
      village.update(action_type: 'no_Game')
      users.update_all(action_type: 'no_Game')
      Message.destroy_all(village_id: current_user.village_id)
      return '村人チームの勝利です。'
    elsif villager_count <= werewolf_count && fox_count.zero?
      village.update(action_type: 'no_Game')
      users.update_all(action_type: 'no_Game')
      Message.destroy_all(village_id: current_user.village_id)
      return '人狼チームの勝利です。'
    elsif 0 < fox_count && (villager_count <= werewolf_count || werewolf_count.zero?)
      village.update(action_type: 'no_Game')
      users.update_all(action_type: 'no_Game')
      Message.destroy_all(village_id: current_user.village_id)
      return '妖狐チームの勝利です。'
    else
      return '人狼はまだ潜んでいます。'
    end
  end

  def get_vote_message
    message = "全員の投票が終わりました。\n" +
              get_voting_result(current_user.village_id) + "\n" +
              judge
  end

  def get_voting_result(village_id)
    votes = Vote.where(village_id: village_id)
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
      target_user = User.find(votes.keys[0])
      target_user.update(is_dead: true)
      message += "\n" + '本日の処刑対象は' + target_user.name + 'さんです。'
    end
    Vote.destroy_all(village_id: village_id)
    message
  end

  def check_all_input
    users = User.where(village_id: current_user.village_id)
                .where.not(action_type: 'wait', is_dead: true)
    if users.count.zero?
      true
    else
      false
    end
  end

  def update_job_number(params)
    @jobs = Job.all
    @jobs.each do |job|
      vs = VillageSetting.where(village_id: params[:id], job_id: job.id.to_s)
      vs.first.update(num: params[:villageSetting][:num][job.id.to_s])
    end
  end

  def set_job(village_id)
    village_settings = VillageSetting.where(village_id: village_id)
                                     .where.not(num: 0).shuffle
    i = 0
    j = 0
    seq_no = 0
    users = User.where(village_id: village_id).shuffle
    users.each do |user|
      j = village_settings[i].num if j.zero?
      user.update(job_id: village_settings[i].job_id, action_type: 'night',
                  is_dead: false, is_protected: true, seq_no: seq_no)
      j -= 1
      i += 1 if j.zero?
      seq_no += 1
    end
  end

  def call_reload(message, taget)
    redirect_to controller: 'villages',
                action: 'reload',
                village_id: current_user.village_id,
                message: message,
                taget: taget
  end

  def do_night_action(params)
    user_id = params[:user_id]
    if current_user.job_id == 1 || current_user.job_id == 3
      params[:level].to_i.times do
        Vote.create(village_id: current_user.village_id,
                    user_id: current_user.id, voted_user: user_id)
      end
    elsif current_user.job_id == 4
      User.find(user_id).update(is_protected: true)
    end
  end
end
