# vendor/plugins/redmine_bibliography/app/controllers/publications_controller.rb

class PublicationsController < ApplicationController
  unloadable
  
  model_object Publication
  before_filter :find_model_object, :except => [:new, :create, :index, :autocomplete_for_project, :add_author, :sort_author_order, :autocomplete_for_author, :get_user_info ]
  
  # before_filter :find_project, :except => [:autocomplete_for_project, :add_author, :sort_authors, :autocomplete_for_author]
    
  def new
    find_project_by_project_id
    @publication = Publication.new
    
    # we'll always want a new publication to have its bibtex entry
    @publication.build_bibtex_entry
    
    # and at least one author
    # @publication.authorships.build.build_author
    
    @project_id = params[:project_id]
    @current_user = User.current    
    
    # TODO - something more interesting here
    @author_options = [["#{User.current.name} (#{User.current.mail})", "#{User.current.class.to_s}_#{User.current.id.to_s}"]]
  end

  def create    
    find_project_by_project_id
    
    @publication = Publication.new(params[:publication])
        
    # @project = Project.find(params[:project_id])
    @publication.projects << @project unless @project.nil?
        
    if @publication.save 
      flash[:notice] = "Successfully created publication."
      redirect_to :action => :show, :id => @publication, :project_id => @project.id
    else
      render :action => 'new'
    end
  end

  def index
    if !params[:project_id].nil?
      find_project_by_project_id
      @project = Project.find(params[:project_id])
      @publications = Publication.find :all, :joins => :projects, :conditions => ["project_id = ?", @project.id]
    else
      @publications = Publication.find :all
    end
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
    find_project_by_project_id unless params[:project_id].nil?
     
    @publication = Publication.find(params[:id])
    @selected_bibtex_entry_type_id = @publication.bibtex_entry.entry_type  
  end

  def update    
    @publication = Publication.find(params[:id])        

    logger.error { "INSIDE THE UPDATE ACTION IN THE PUBLICATION CONTROLLER" }

    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Successfully updated Publication."

      if !params[:project_id].nil?
        redirect_to :action => :show, :id => @publication, :project_id => params[:project_id]
      else
        redirect_to :action => :show, :id => @publication
      end
    else
      render :action => 'edit'
    end   
  end

  def show
    find_project_by_project_id unless params[:project_id].nil?
    
    if @publication.nil?
      @publications = Publication.all
      render "index", :alert => 'The publication was not found!'
    else
      @authors = @publication.authors
      @bibtext_entry = @publication.bibtex_entry
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
  
  def autocomplete_for_project
    @publication = Publication.find(params[:id])
        
    @projects = Project.active.like(params[:q]).find(:all, :limit => 100) - @publication.projects            
    logger.debug "Query for \"#{params[:q]}\" returned \"#{@projects.size}\" results"
    render :layout => false
  end

  def autocomplete_for_author    
    @results = []
    
    object_id = params[:object_id]
    @object_name = "publications[authorships_attributes][#{object_id}][search_results]"
        
    authorships_list = Authorship.like_unique(params[:q]).find(:all, :limit => 100)
    users_list = User.active.like(params[:q]).find(:all, :limit => 100)

    logger.debug "Query for \"#{params[:q]}\" returned \"#{authorships_list.size}\" authorships and \"#{users_list.size}\" users"
    
    @results = users_list

    # TODO: can be optimized…    
    authorships_list.each do |authorship|      
      flag = true
      
      users_list.each do |user|
        if authorship.name == user.name && authorship.email == user.mail && authorship.institution == user.institution
          Rails.logger.debug { "Rejecting Authorship #{authorship.id}" }
          flag = false
          break
        end
      end

      @results << authorship if flag
    end

    render :layout => false    
  end
  
  
  def get_user_info
    object_id = params[:object_id]
    value = params[:value]
    classname = Kernel.const_get(value.split('_')[0])

    item = classname.find(value.split('_')[1])

    name_field = "publication_authorships_attributes_#{object_id}_name_on_paper".to_sym
    email_field = "publication_authorships_attributes_#{object_id}_email".to_sym
    institution_field = "publication_authorships_attributes_#{object_id}_institution".to_sym
    
    yes_radio = "publication_authorships_attributes_#{object_id}_identify_author_yes".to_sym
    
    respond_to do |format|
      format.js {logger.error { "JS" }
        render(:update) {|page| 
          page[name_field].value = item.name
          page[email_field].value = item.mail
          page[institution_field].value = item.institution

          page[yes_radio].checked = true
          page[name_field].readOnly = true
          page[email_field].readOnly = true
          page[institution_field].readOnly = true
        }
      }
    end
  end

  def sort_author_order
    params[:authorships].each_with_index do |id, index|
      Authorship.update_all(['auth_order=?', index+1], ['id=?', id])
    end
    render :nothing => true
  end

  def add_project
    @projects = Project.find(params[:publication][:project_ids])    
    @publication.projects << @projects
    @project = Project.find(params[:project_id])    
    
    # TODO luisf should also respond to HTML??? 
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { 
        render(:update) {|page| 
          page[:add_project_form].reset          
          page.replace_html :list_projects, :partial => 'list_projects'
        }
      }
    end
  end
  
  
  def remove_project
    @project = Project.find(params[:project_id])
    proj = Project.find(params[:remove_project_id])

    if @publication.projects.length > 1
      if @publication.projects.exists? proj
        @publication.projects.delete proj if request.post?
      end
    else
      logger.error { "Cannot remove project from publication list" }      
    end
    
    logger.error { "CURRENT project name#{proj.name} and wanna delete #{@project.name}" }
        
    render(:update) {|page| 
      page.replace_html "list_projects", :partial => 'list_projects', :id  => @publication
    }    
  end
    
  def destroy
    find_project_by_project_id
    
    @publication.destroy
        
    flash[:notice] = "Successfully deleted Publication."
    redirect_to :controller => :publications, :action => 'index', :project_id => @project
  end

  private

end
