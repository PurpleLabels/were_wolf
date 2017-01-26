 App.room = App.cable.subscriptions.create "RoomChannel",
   connected: ->
     # Called when the subscription is ready for use on the server

   disconnected: ->
     # Called when the subscription has been terminated by the server

   received: (data) ->
     # Called when there's incoming data on the websocket for this channel
     #alert data['message']
     
     $('#users').empty()
     $('#users').append data['message']
     $("#count").html data['count'];
     calc()
     console.log('レシーブ！!!!！')
     #alert data['message']
     #$('#result').val(data['message'])

 
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

