class VillagesController < ApplicationController
  def show
    @village = Village.find(params[:id])
    @user = User.find(current_user.id)
    @user.village_id = @village.id
    @user.save
    @users = User.where("village_id = "+params[:id])
    #@villageSettings = VillageSetting.joins("INNER JOIN jobs ON village_settings.job_id = jobs.id").select('village_settings.*,jobs.*').where("village_id = "+params[:id] )
    @villageSettings = VillageSetting.joins(:job).select("village_settings.*,jobs.*").where("village_id = "+params[:id] )

  end
  
  def update
    byebug
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
        @rr = ApplicationController.renderer.render(@users)
        ActionCable.server.broadcast "village:#{@village_id}", message: @rr,count:@users.count
      end
    end
    
  end
end
