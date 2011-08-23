class AuthorsController < ApplicationController
  
  def index
    @authors = Author.find(:all)
  end

  def show
    @author = Author.find(params[:id])  

  end

end
