App.room = App.cable.subscriptions.create "RoomChannel",
    connected: ->
        # Called when the subscription is ready for use on the server

    disconnected: ->
        # Called when the subscription has been terminated by the server

    received: (data) ->
        # Called when there's incoming data on the websocket for this channel
            $("#count").html data['count'];
            calc()
            reload(data['village_id'],data['user_id'])
            if data['message'] != ''
                alert data['message']

    enter: (message) ->
        @perform 'enter', message: message

    in_out: (message) ->
        @perform 'in_out', message: message
