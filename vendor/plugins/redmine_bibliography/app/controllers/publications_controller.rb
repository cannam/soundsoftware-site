# vendor/plugins/redmine_bibliography/app/controllers/publications_controller.rb

class PublicationsController < ApplicationController

  # parse string with bibtex authors
  # return an ordered array
  def parse_authors
    
  end

  def parse_bibtex_file
  
  end

  def parse_bibtex_text
    bibtex_entry = params[:bibtex_entry]

    if bibtex_entry
      bib = BibTeX.parse bibtex_entry
      
      # parses the bibtex entries
      bib.data.map do |d|
        result = ''
        if d.class == BibTeX::Entry
          #    d.replace!(bib.strings)
          result = [d.author, '. ', d.title].join
        end

        logger.error result
      end
    end
  end 

  def new 
    session[:publication_params] ||= {}
    @publication = Publication.new
    @publication.current_step = session[:publication_step]

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
