module UsersHelper
  def get_action(user)
    if current_user.action_type == 'night' && !current_user.is_dead && user.id != current_user.id
      if current_user.job_id == 1
        if user.job_id == 1
          '人狼'
        else
          link_to '殺す', night_village_games_path(village_id: current_user.village_id, user_id: user.id, level: 1), remote: true
        end
      elsif current_user.job_id == 3
        link_to '占う', night_village_games_path(village_id: current_user.village_id, user_id: user.id), remote: true, onclick: 'reading(' + user.id.to_s + ",'" + user.name + "'," + user.job_id.to_s + ')'
      elsif current_user.job_id == 4
        link_to '守る', night_village_games_path(village_id: current_user.village_id, user_id: user.id), remote: true
      elsif current_user.job_id == 5
        link_to '疑う', night_village_games_path(village_id: current_user.village_id, user_id: user.id), remote: true
      else
        link_to '疑う', night_village_games_path(village_id: current_user.village_id, user_id: user.id), remote: true
      end
    elsif current_user.action_type == 'vote' && !current_user.is_dead
      link_to '投票', vote_village_games_path(village_id: current_user.village_id, user_id: user.id), remote: true
    end
  end
end

def get_job(user)
  if current_user.action_type == 'no_Game' || user.id == current_user.id || current_user.job_id == 1 && user.job_id == 1
    Job.find(user.job_id).name
  elsif current_user.job_id == 5 && user.is_dead
    check_human(user)
  else
    '正体不明'
  end
end

def get_status(user)
  if user.is_dead
    image_tag('dead.png', class: 'circle')
  else
    image_tag('alive.png', class: 'circle')
  end
end

def check_human
  if user.job_id == 1
    '人狼'
  else
    '人間'
  end
end
