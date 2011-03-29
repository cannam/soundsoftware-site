class PublicationsController < ApplicationController

  def new
    @publication = Publication.new()
  end

  def create
    @publication.save!
  end

  def index
    @publications = Publication.find(:all)
  end

  def edit
  end

  def update
  end

  def show  
    @publication = Publication.find(params[id])
    @authors = @publication.authors
  end


end
