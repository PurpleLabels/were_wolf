class UsersController < ApplicationController
  before_action :authenticate_user!, except: :show
  before_action :admin_user,         only:   :destroy
  def show
    @user = User.find(params[:id])
  end
end
