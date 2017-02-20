 class RoomChannel < ApplicationCable::Channel
   def subscribed
     # stream_from "some_channel"
     #stream_from "room_channel"
     setUser(current_user.village_id.to_s)
   end

   def unsubscribed
     # Any cleanup needed when channel is unsubscribed
   end
   
   def in_out(data)
      #Message.create! content: data['message']
      #ActionCable.server.broadcast 'room_channel', message: data['message']
      setUser(data['message'])
   end
   
   private
    def setUser(village_id)
        stop_all_streams
        stream_from "village:#{village_id}"
        @users = User.where("village_id = "+village_id)
        #@rr = ApplicationController.renderer.render(@users)
        ActionCable.server.broadcast "village:#{village_id}",count:@users.count,Action:'show',village_id:village_id.to_s,user_id:current_user.id
    end
 end
