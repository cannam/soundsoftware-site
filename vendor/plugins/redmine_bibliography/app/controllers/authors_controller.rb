class AuthorsController < ApplicationController
  helper :publications
  include PublicationsHelper
  
  def index
    @authors = Author.find(:all)
  end

  def show
    @author = Author.find(params[:id])
  end

end
