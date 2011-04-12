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

    logger.error bibtex_entry

    if bibtex_entry
      bib = BibTeX.parse bibtex_entry

      # parses the bibtex entries
      bib.data.map do |d|
        result = ''
        if d.class == BibTeX::Entry
          @bentry = BibtexEntry.new
          #    d.replace!(bib.strings)

          d.fields.keys.map do |k|
            if k == "title"
              @publication.title = d[k]
            else
              @bentry[k] = d[k]
            end
          end
        end               
      end
      
      @publication.bibtex_entry = @bentry
      
      if @publication.save
        logger.error "SAVED"
      else
        logger.error "NOT SAVED"
      end

      logger.error @publication.bibtex_entry

    end 
  end

  def new 
    @publication = Publication.new
    @publication.current_step = session[:publication_step]

  end

  def create    
    @publication = Publication.new(params[:publication])
    @publication.current_step = session[:publication_step]

    parse_bibtex_text



    if params[:back_button]
      @publication.previous_step
    else
      @publication.next_step
    end

    session[:publication_step] = @publication.current_step

    render "new"
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
