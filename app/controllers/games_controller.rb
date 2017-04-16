class GamesController < ApplicationController
  include Common
  def new
    update_action_type('night')
    User.where(village_id: current_user.village_id)
        .update_all(is_protected: true)
    set_job(params[:format])
    Vote.destroy_all(village_id: current_user.village_id)
    reload('ゲームを開始します。', 'all')
  end

  def night
    do_night_action(params)
    current_user.update(action_type: 'wait')
    if check_all_input
      message = get_night_message
      update_action_type('day')
      User.where(village_id: current_user.village_id)
          .update_all(is_protected: false)
      reload(message, 'all')
    else
      reload(nil, 'myself')
    end
  end

  def stop
    update_action_type('no_Game')
    reload('ゲームを終了します。', 'all')
  end

  def to_vote
    update_action_type('vote')
    reload('投票の時間です。', 'all')
  end

  def vote
    Vote.create(village_id: current_user.village_id,
                user_id: current_user.id,
                voted_user: params[:user_id])
    current_user.update(action_type: 'wait')
    if check_all_input
      message = get_vote_message
      if message.include?('投票結果が同数です。再度投票してください。')
        update_action_type('vote')
      else
        update_action_type('night')
      end
      reload(message, 'all')
    else
      reload(nil, 'myself')
    end
  end
end
