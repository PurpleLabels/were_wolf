module UsersHelper
  def get_status(user)
    unless current_user.action_type == 'wait' || current_user.action_type == 'no_Game'
      if user.is_dead
        status = '死亡'
        if current_user.job_id == 5
          status = if user.job_id == 1
                     status + ' 人狼'
                   else
                     status + ' 人間'
                   end
        end
        return status
      elsif user.id == current_user.id
        Job.find(current_user.job_id).name
      else
        if current_user.action_type == 'night' && !current_user.is_dead
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
  end
end
