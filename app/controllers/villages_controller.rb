class VillagesController < ApplicationController
  def reload
    @users = User.where("village_id = "+params[:village_id].to_s )
    @village = Village.find(params[:village_id])
    @villageSettings = VillageSetting.joins(:job).select("village_settings.*,jobs.*").where("village_id = "+params[:village_id] )
    day = 0
    night = 0
    wait = 0
    vote = 0
    dead = 0
    @users.each{|user|
      if user.action_type == 0
        wait = wait + 1
      elsif user.action_type == 1
        day = day + 1
      elsif user.action_type == 2
        night = night + 1
      elsif user.action_type == 3
        vote = vote + 1
      elsif user.action_type == 4
        dead = dead + 1
      end
    }
    if @village.action_type == 7
        @village.action_type = 2
        @village.save
        ActionCable.server.broadcast "village:#{@village.id}",count:@users.count,Action:'show',village_id:@village.id.to_s,user_id:current_user.id
    elsif @users.count == wait + dead && @village.action_type == 2
        @users.each{|user|
          user.action_type = 1
          user.save
        }
        @village.action_type = 1
        @village.save
        message ="全員の夜のアクションが終わりました。"
        ActionCable.server.broadcast "village:#{@village.id}",count:@users.count,Action:'night',village_id:@village.id.to_s,message:message,user_id:current_user.id
    elsif @users.count == wait + dead && @village.action_type == 3
        @users.each{|user|
          user.action_type = 2
          user.save
        }
        @village.action_type = 2
        @village.save
        message ="全員の投票が終わりました。\n 本日の処刑対象はxxさんです。"
        ActionCable.server.broadcast "village:#{@village.id}",count:@users.count,Action:'night',village_id:@village.id.to_s,message:message,user_id:current_user.id
    elsif @users.count == wait + dead && @village.action_type == 5
        @village.action_type = 0
        @village.save
        message ="ゲームが中断されました。"
        ActionCable.server.broadcast "village:#{@village.id}",count:@users.count,Action:'stop',village_id:@village.id.to_s,message:message,user_id:current_user.id
    elsif @village.action_type == 6
      @village.action_type = 3
      @village.save
      ActionCable.server.broadcast "village:#{@village.id}",count:@users.count,Action:'to_vote',village_id:@village.id.to_s,message:message,user_id:current_user.id
    end
  end
  
  def start
    @villageSettings = VillageSetting.where("village_id = "+params[:format] + " and num <> 0")
    @villageSettings = @villageSettings.shuffle
    @village = Village.find(params[:format])
    @village.action_type = 7
    @village.save
    @users = User.where("village_id = "+params[:format] )
    i = 0
    j = 0
    @users.each{|user|
      if (j == 0)
        j = @villageSettings[i].num
      end
      user.job_id =@villageSettings[i].job_id
      user.action_type = 2
      user.save
      j = j - 1
      if (j == 0)
        i = i + 1
      end
    }
    @villageSettings = VillageSetting.joins(:job).select("village_settings.*,jobs.*").where("village_id = "+params[:format] )

    #ActionCable.server.broadcast "village:#{params[:format]}",village_id:params[:format]
    redirect_to :action => "reload", :village_id => current_user.village_id
  end
  
  def day
    #byebug
    getUser(params[:format])
  end
  
  def night
    #人狼の場合
    if current_user.job_id == 1
      num = 0
      level = params[:level].to_i
      while num < level do
        print("num = ", num)
        num = num + 1
      end
    end
    current_user.action_type = 0
    current_user.save
    redirect_to :action => "reload", :village_id => current_user.village_id
  end
  
  def to_vote
    @users = User.where("village_id = "+params[:village_id] )
    @users.each{|user|
      user.action_type = 3
      user.save
    }
    @village = Village.find(params[:village_id])
    @village.action_type = 6
    @village.save
    redirect_to :action => "reload", :village_id => current_user.village_id
  end
  
  def vote
    @vote = Vote.create
    @vote.village_id = current_user.village_id
    @vote.user_id = current_user.id
    
    @vote.voted_user = params[:user_id]
    @vote.save
    
    current_user.action_type = 0
    current_user.save

    redirect_to :action => "reload", :village_id => current_user.village_id
  end
  
  def stop
    @users = User.where("village_id = "+params[:format] )
    @village = Village.find(params[:format])
    @village.action_type = 5
    @village.save
    @villageSettings = VillageSetting.joins(:job).select("village_settings.*,jobs.*").where("village_id = "+params[:format] )
    @users.each{|user|
      user.job_id = 1
      user.action_type = 0
      user.save
    }
    redirect_to :action => "reload", :village_id => current_user.village_id
  end
  
  def show
    @village = Village.find(params[:id])
    @user = User.find(current_user.id)
    @user.village_id = @village.id
    @user.action_type = 0
    @user.save
    @users = User.where("village_id = "+params[:id])
    #@villageSettings = VillageSetting.joins("INNER JOIN jobs ON village_settings.job_id = jobs.id").select('village_settings.*,jobs.*').where("village_id = "+params[:id] )
    @villageSettings = VillageSetting.joins(:job).select("village_settings.*,jobs.*").where("village_id = "+params[:id] )

  end
  
  def update
    
    @village = Village.find(params[:id])
    @village.day_time = params[:village][:day_time]
    @village.night_time = params[:village][:night_time]
    @village.vote_time = params[:village][:vote_time]
    @village.save

    @jobs = Job.all
    @jobs.each{|job|
      vs = VillageSetting.where("village_id = "+@village.id.to_s+" and job_id =" + job.id.to_s)
      vs.first.num = params[:villageSetting][:num][job.id.to_s]
      vs.first.save
    }
    redirect_to :action => "show", :id => params.require(:id)
  end
  
  def new
    if signed_in?
      @village  = Village.new
    end
  end
  
  def create
    village = params.require(:village).permit(:name, :password)
    
    @village = Village.create(village)
    @village.is_played = false
    @village.day_time = 2
    @village.night_time = 60
    @village.vote_time = 20
    @village.action_type = 0
    @village.save
    
    @jobs = Job.all
    
    @jobs.each{|job|
      vs = VillageSetting.new(village_id: @village.id, job_id: job.id, num:0)
      vs.save
    }

    @user = User.find(current_user.id)
    @user.village_id = @village.id
    @user.is_admin = true

    @user.save
    flash[:success] = "village created!"
    redirect_to :action => "show", :id => @village.id

  end
  
  def search
    @villages = Village.all
    @user = User.find(current_user.id)
    @village_id = @user.village_id

    if @village_id != nil
      @users = User.where("village_id = "+@village_id.to_s )
      if @users.count == 1
        # この辺でバグ
        @users.update_all({village_id:nil,is_admin:false})
        Village.destroy(@user.village_id)
      else
        if @user.is_admin
          @remains = User.where("village_id = "+@village_id.to_s+" and is_admin = false")
          @remains.first.update({is_admin:true})
          @remains.first.save
        end
        @user.update({village_id:nil,is_admin:false})
        @user.save
        #@rr = ApplicationController.renderer.render(@users)
        ActionCable.server.broadcast "village:#{@village_id}",count:@users.count, village_id:@village_id.to_s,Action:'show',user_id:current_user.id
      end
    end
    
  end
  
  private
    def getUser(village_id)
        @users = User.where("village_id = "+village_id)
    end
end
