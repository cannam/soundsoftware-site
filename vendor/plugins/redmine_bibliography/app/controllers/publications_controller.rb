# vendor/plugins/redmine_bibliography/app/controllers/publications_controller.rb

class PublicationsController < ApplicationController
  unloadable
  
  before_filter :find_project_by_project_id, :except => [:autocomplete_for_project, :add_author, :sort_authors, :autocomplete_for_author]
    
  def new
    @publication = Publication.new      
    
    # we'll always want a new publication to have its bibtex entry
    # @publication.build_bibtex_entry
    
    # and at least one author
    # @publication.authorships.build.build_author
    
    @project_id = params[:project_id]
    @current_user = User.current
  end


  def create
    @publication = Publication.new(params[:publication])
    
    logger.error { "PUBLICATION CREATE ACTION" }
    logger.error { params[:publication]  }
    
    
    @project = Project.find(params[:project_id])

    logger.error { "PARAMS publication" }
    logger.error { params[:publication] }
    
    @publication.projects << @project
    
    if @publication.save 
      flash[:notice] = "Successfully created publication."
      redirect_to :action => :show, :id => @publication, :project_id => @project.id
    else
      render :action => 'new'
    end
  end

  def index
    @project = Project.find(params[:project_id])
    @publications = Publication.find :all, :joins => :projects, :conditions => ["project_id = ?", @project.id]
  end

  def new_from_bibfile
    @publication.current_step = session[:publication_step]
    
    # contents of the paste text area
    bibtex_entry = params[:bibtex_entry]

    # method for creating "pasted" bibtex entries
    if bibtex_entry
      parse_bibtex_list bibtex_entry    
    end
  end

  def add_author
    if (request.xhr?)
      render :text => User.find(params[:user_id]).name
    else
      # No?  Then render an action.
      #render :action => 'view_attribute', :attr => @name
      logger.error { "ERRO ADD AUTHOR" }
    end
  end

  def edit    
    @publication = Publication.find(params[:id])
  end

  def update    
    @publication = Publication.find(params[:id])        
    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Successfully updated Publication."
      redirect_to @publication
    else
      render :action => 'edit'
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
  
  def add_project
    @projects = Project.find(params[:publication][:project_ids])    
    @publication = Publication.find(params[:id])        
    @publication.projects << @projects
    
    # TODO luisf should also respond to HTML??? 
    respond_to do |format|
      format.js      
    end
  end

  def autocomplete_for_project
    @publication = Publication.find(params[:id])
        
    @projects = Project.active.like(params[:q]).find(:all, :limit => 100) - @publication.projects            
    logger.debug "Query for \"#{params[:q]}\" returned \"#{@projects.size}\" results"
    render :layout => false
  end

  def autocomplete_for_author
    @results = []
    
    authors_list = Author.like(params[:q]).find(:all, :limit => 100)    
    users_list = User.active.like(params[:q]).find(:all, :limit => 100)

    logger.debug "Query for \"#{params[:q]}\" returned \"#{authors_list.size}\" authors and \"#{users_list.size}\" users"
    
    # need to subtract both lists
    # give priority to the users    
    users_list.each do |user|      
      @results << user
    end
    
    authors_list.each do |author|      
      @results << author unless users_list.include?(author.user_id)
    end
                 
    render :layout => false
  end

  def sort_authors
    params[:authors].each_with_index do |id, index|
      Author.update_all(['order=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end

  def identify_author
    
  end


  
  private
   
  # TODO: luisf. - only here for debugging purposes 
  # Find project of id params[:project_id]
   def find_project_by_project_id
     
     logger.error { "FIND PROJECT BY PROJECT ID" }
     
     @project = Project.find(params[:project_id])
   rescue ActiveRecord::RecordNotFound
     render_404
   end
end
