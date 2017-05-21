class GamesController < ApplicationController
  include Common
  def new
    update_action_type_on_start('night')
    User.where(village_id: current_user.village_id)
        .update_all(is_protected: true)
    set_job(current_user.village_id)
    Message.destroy_all(village_id: current_user.village_id)
    Vote.destroy_all(village_id: current_user.village_id)
    call_reload('ゲームを開始します。', 'all')
  end

  def night
    do_night_action(params)
    current_user.update(action_type: 'wait')
    if check_all_input
      message = get_night_message
      update_action_type('day')
      User.where(village_id: current_user.village_id)
          .update_all(is_protected: false)
      call_reload(message, 'all')
    else
      call_reload(nil, 'myself')
    end
  end

  def stop
    update_action_type('no_Game')
    Message.destroy_all(village_id: current_user.village_id)
    call_reload('ゲームを終了します。', 'all')
  end

  def to_vote
    update_action_type('vote')
    call_reload('投票の時間です。', 'all')
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
        Message.destroy_all(village_id: current_user.village_id)
        update_action_type('night')
      end
      call_reload(message, 'all')
    else
      call_reload(nil, 'myself')
    end
  end

  def tweet
    Message.create(village_id: current_user.village_id,
                   message_type: 'tweet',
                   content: current_user.name +
                   ':' + params[:user_name] + 'を殺そう')
    call_reload('', 'all')
  end
end
