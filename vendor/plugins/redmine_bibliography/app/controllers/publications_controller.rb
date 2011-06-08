# vendor/plugins/redmine_bibliography/app/controllers/publications_controller.rb

class PublicationsController < ApplicationController
  # TODO: should be removed on production version?
  unloadable

  def new
    @publication = Publication.new      
    
    # we'll always want a new publication to have its bibtex entry
    @publication.build_bibtex_entry
    
    # the step we're at in the form
    @publication.current_step = session[:publication_step]

    @new_publications = []
    session[:publications] ||= {}
  end

  def create
    @publication = Publication.new(params[:publication])

    if @publication.save
      flash[:notice] = "Successfully created publication."
      redirect_to @publication
    else
      render :action => 'new'
    end
  end

  def index
    @publications = Publication.find(:all)
  end

  def new_from_bibfile
    @publication.current_step = session[:publication_step]
    
    # contents of the paste text area
    bibtex_entry = params[:bibtex_entry]

    # method for creating "pasted" bibtex entries
    if bibtex_entry
      logger.error "ANTES PARSE"      
      parse_bibtex_list bibtex_entry    
      logger.error "DEPOIS PARSE"
    end

    # form's flow control
    if params[:back_button]
      @publication.previous_step
    else
      @publication.next_step
    end

    session[:publication_step] = @publication.current_step
    
  end


  def edit    
    @publication = Publication.find(params[:id])
  end

  def update    
    @publication = Publication.find(params[:id])
        
    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Successfully updated Publication."
    else
      flash[:notice] = "Could not Update Publication."
    end
    
  end

  def show
    logger.error "-------> No Show"
    
    @publication = Publication.find(params[:id])

    if @publication.nil?
        @publications = Publication.all
        render "index", :alert => 'Your Publications was not found!'
    else
      @authors = @publication.authors
      @bibtext_entry = @publication.bibtex_entry
    
      respond_to do |format|
        format.html
        format.xml {render :xml => @publication}
      end
    end
  end

  # parse string with bibtex authors
  def parse_authors(authors_entry)
    # in bibtex the authors are always seperated by "and"
    return authors_entry.split(" and ")
  end

  # parses a list of bibtex 
  def parse_bibtex_list(bibtex_list)
    bibliography = BibTeX.parse bibtex_list

    no_entries = bibliography.data.length

    # parses the bibtex entries
    bibliography.data.map do |d|

      if d.class == BibTeX::Entry
        create_bibtex_entry d
      end
    end
  end 

  def create_bibtex_entry(d)        
    @publication = Publication.new
    @bentry = BibtexEntry.new        
    authors = []
    institution = ""
    email = ""

    d.fields.keys.map do |field|
      case field.to_s
      when "author"
        authors = parse_authors d[field]
      when "title"
        @publication.title = d[field]
      when "institution"
        institution = d[field]
      when "email"
        email = d[field]
      else
        @bentry[field] = d[field]
      end
    end 

    @publication.bibtex_entry = @bentry
    @publication.save

    # what is this for??? 
    # @created_publications << @publication.id

    # need to save all authors
    #   and establish the author-publication association 
    #   via the authorships table 
    authors.each_with_index.map do |authorname, idx|
      author = Author.new(:name => authorname)
      if author.save!
        puts "SAVED"
      else
        puts "NOT SAVED"
      end

      author.authorships.create!(
        :publication => @publication,
        :institution => institution,
        :email => email,
        :order => idx)

    end
  end

  # parses the bibtex file
  def parse_bibtex_file

  end

  def import
    @publication = Publication.new
    
    
  end

  def review_new_entries

  end


end
