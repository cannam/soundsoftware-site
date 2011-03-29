class AuthorsController < ApplicationController
  
  def index
    @authors = Author.find(:all)

  end
end
