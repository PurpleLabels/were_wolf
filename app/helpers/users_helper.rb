module UsersHelper
  def get_action(user)
    if current_user.action_type == 'night' && !current_user.is_dead && user.id != current_user.id && !user.is_dead
      if current_user.job_id == 1
        if user.job_id != 1
          link_to '殺す', get_night_action_path(user), remote: true, class: get_button_class, onclick:'disabled()'
        end
      elsif current_user.job_id == 3
        link_to '占う', get_night_action_path(user), remote: true, class: get_button_class, onclick: 'reading(' + user.id.to_s + ",'" + user.name + "'," + user.job_id.to_s + ')'
      elsif current_user.job_id == 4
        link_to '守る', get_night_action_path(user), remote: true, class: get_button_class, onclick:'disabled()'
      elsif current_user.job_id == 5
        link_to '疑う', get_night_action_path(user), remote: true, class: get_button_class, onclick:'disabled()'
      else
        link_to '疑う', get_night_action_path(user), remote: true, class: get_button_class, onclick:'disabled()'
      end
    elsif current_user.action_type == 'vote' && !current_user.is_dead && user.id != current_user.id && !user.is_dead
      link_to '投票', vote_village_games_path(village_id: current_user.village_id, user_id: user.id), remote: true, class: get_button_class, onclick:'disabled()'
    end
  end
end

def get_job(user)
  if current_user.action_type == 'no_Game' ||
     user.id == current_user.id ||
     (current_user.job_id == 1 || current_user.job_id == 7) && user.job_id == 1 ||
     current_user.job_id == 8 && user.job_id == 8
    Job.find(user.job_id).name
  elsif current_user.job_id == 5 && user.is_dead
    check_human(user)
  else
    '正体不明'
  end
end

def get_tweet_link(user)
  if current_user.job_id == 1
    link_to get_status(user), tweet_village_games_path(village_id: current_user.village_id, user_name: user.name), remote: true
  else
    get_status(user)
  end
end

def get_status(user)
  if current_user.action_type == 'no_Game'
    get_job_icon(user.job_id)
  else
    if user.is_dead
      image_tag('dead.png', class: 'circle')
    else
      image_tag('villager.png', class: 'circle')
    end
  end
end

def get_button_class
  'waves-effect waves-light btn'
end

def get_night_action_path(user)
  night_village_games_path(village_id: current_user.village_id, user_id: user.id, level: 1)
end

def check_human(user)
  if user.job_id == 1
    '人狼'
  else
    '人間'
  end
end
