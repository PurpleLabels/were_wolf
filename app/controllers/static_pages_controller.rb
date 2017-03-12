class StaticPagesController < ApplicationController
  def home
    @info = 1
  end

  def help; end

  def search_village
    @villages = Village.all
  end

  def creat_village; end
end
