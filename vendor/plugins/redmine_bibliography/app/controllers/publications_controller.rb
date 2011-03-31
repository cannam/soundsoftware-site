class PublicationsController < ApplicationController

  def new
    
    @publication = Publication.new(params[:publication])
    
    if @publication.save
      logger.error "GRAVOU XXXdsfgXXX"
    else
      logger.error "nao gravou"
    end
    
  end

  def create
    
    logger.error "AAAA create"
    
    @publication.save
  end

  def index
    @publications = Publication.find(:all)
  end

  def edit
        logger.error "AAAA edit"

  end

  def update
    
        logger.error "AAAA update"


  end

  def show  
    @publication = Publication.find(params[id])
    @authors = @publication.authors
  end


end
