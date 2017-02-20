 App.room = App.cable.subscriptions.create "RoomChannel",
   connected: ->
     # Called when the subscription is ready for use on the server

   disconnected: ->
     # Called when the subscription has been terminated by the server

   received: (data) ->
     # Called when there's incoming data on the websocket for this channel
     #alert data['message']
     
     #if data['Action'] == 'show'
      # $('#users').empty()
      # $('#users').append data['message']
      $("#count").html data['count'];
      # console.log('cal前')
      calc()
      #window.location.href = '/villages/reload.' + village_id
      #reload(data['village_id'])
      console.log(data['Action'])
      if data['Action'] == 'night'
       alert data['message']
       reload(data['village_id'],data['user_id'])
      else if data['Action'] == 'stop'
       alert data['message']
       reload(data['village_id'],data['user_id'])
      else if data['Action'] == 'vote'
       alert data['message']
       reload(data['village_id'],data['user_id'])
      else if data['Action'] == 'show'
       reload(data['village_id'],data['user_id'])
      else if data['Action'] == 'to_vote'
       alert '投票の時間です。'
       reload(data['village_id'],data['user_id'])
     
   enter: (message) ->
     @perform 'enter', message: message
     console.log "enter"
     
   in_out: (message) ->
     @perform 'in_out', message: message

   
   #App.room.in_out $('#yyy').val()
# $(window).load ->
#   $('#btn').click ->
#     # console.log(current_user_id)
#     # console.log(current_user_name)
#     alert $('#yyy').val()
#     App.room.in_out $('#yyy').val()
#     $('#yyy').val('')
#
 # $(document).on 'keypress', '[data-behavior~=room_in_outer]', (event) ->
 #     alert 'aaaaa'
 #     App.room.in_out event.target.value
 #     event.target.value = ''
 #     event.preventDefault()

