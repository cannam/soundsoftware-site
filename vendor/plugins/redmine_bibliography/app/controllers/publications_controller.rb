class PublicationsController < ApplicationController

  def parse_bibtex_text

    logger.error "BBBBBBBB"

    bibtex_entry = params[:bibtex_entry]




    #    logger.error bibtex_entry

    if bibtex_entry
      Bibtex::Parser.parse_string(bibtex_entry).map do |entry|
        logger.error entry[:title]
        logger.error entry[:year]
        logger.error entry.type  
      end
    end

    logger.error "FIM"

  end 

  def new

    logger.error "AAAAAA"

    logger.error request.request_method

    if request.post?
      parse_bibtex_text
      @publication = Publication.new(params[:publication])

      if @publication.save
        logger.error "GRAVOU XXXdsfgXXX"
      else
        logger.error "nao gravou"
      end

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
