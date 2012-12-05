# -*- coding: utf-8 -*-
# vendor/plugins/redmine_bibliography/app/controllers/publications_controller.rb

class BibtexParsingError < Exception; end

class PublicationsController < ApplicationController
  unloadable

  model_object Publication
  before_filter :find_model_object, :except => [:parse_bibtex, :new, :create, :create_from_bibtex, :index, :get_bibtex_required_fields, :autocomplete_for_project, :add_author, :sort_author_order, :autocomplete_for_author, :get_user_info ]
  before_filter :find_project_by_project_id, :authorize, :only => [ :edit, :new, :update, :create ]

  def new
    find_project_by_project_id
    @publication = Publication.new

    # we'll always want a new publication to have its bibtex entry
    @publication.build_bibtex_entry

    # and at least one author
    # @publication.authorships.build.build_author
    # todo - do we still need this? --lf.20121205
    @author_options = [["#{User.current.name} (@#{User.current.mail.partition('@')[2]})", "#{User.current.class.to_s}_#{User.current.id.to_s}"]]
  end

  # the argument is a ruby-bibtex parsed entry
  def create_bibtex_entry(bibtex)

    bibtex.fields.keys.map do |field|
      case field.to_s
      when "title"
        @publication.title = bibtex[field]
      when "author"
        bibtex.authors.each do |auth|
          logger.error { "AUTHOR #{auth}" }
        end
      else
        @publication.bibtex_entry[field] = bibtex[field]
      end
    end
  end

  def parse_bibtex
    find_project_by_project_id
    @bibtex_parse_success = true

    @publication = Publication.new
    @publication.build_bibtex_entry

    begin
      bibtex_paste = params[:bibtex_paste]
      bib = BibTeX.parse(bibtex_paste)
    rescue
      # todo: output errors to user
      # bib.errors.present?
      @bibtex_parse_success = false
      # @bibtex_parsing_error = bib.errors[0].trace[4]
      # logger.error { "BibTex Parsing Error: #{@bibtex_parsing_error}" }
      logger.error { "BibTex Parsing Error" }
    end

    # suggest likely authors/users from database
    @suggested_authors = {}

    respond_to do |format|
        if @bibtex_parse_success
          # todo: should this code be here?

          # creates the entry
          create_bibtex_entry(bib[0])
          logger.error { "Bibtex Entry #{@bibtex_entry}" }

          @ieee_prev = CiteProc.process bib.to_citeproc, :style => :ieee, :format => :html
          bibtex_parsed_authors = bib[0].authors

          # creates stucture with author suggestions
          bibtex_parsed_authors.each do |auth|
            @suggested_authors[auth] = suggest_authors(auth.last)

            @publication.authorships.new :name_on_paper => auth
            logger.error { "Added Authorship: #{auth}" }
          end

          # we can now temporarily save this publication
          # note that the publication still needs reviewing
          # we are skipping the validation we only have authorships
          # associated with the publication at this stage

          # in Rails 3 this should be changed to :validate => false
          @publication.save(false)
        end

        # todo: response for HTML
        format.js
    end
  end

  def create_from_bibtex
    find_project_by_project_id

    debugger

  end

  def create
    @project = Project.find(params[:project_id])

    @author_options = []

    @publication = Publication.new(params[:publication])
    @publication.projects << @project unless @project.nil?

    if @publication.save
      @publication.notify_authors_publication_added(@project)

      flash[:notice] = "Successfully created publication."
      redirect_to :action => :show, :id => @publication, :project_id => @project
    else
      render :action => 'new', :project_id => @project
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


  def get_bibtex_required_fields
    fields = BibtexEntryType.fields(params[:q])

    respond_to do |format|
      format.js {
        render(:update) {|page|
          if params[:q].empty?
            page << "hideOnLoad();"
          else
            page << "show_required_bibtex_fields(#{fields.to_json()});"
          end
        }
      }

    end
  end


  def add_author
    if (request.xhr?)
      render :text => User.find(params[:user_id]).name
    else
      # No?  Then render an action.
      #render :action => 'view_attribute', :attr => @name
      logger.error { "Error while adding Author to publication." }
    end
  end


  def edit
    find_project_by_project_id unless params[:project_id].nil?

    @edit_view = true;
    @publication = Publication.find(params[:id])
    @selected_bibtex_entry_type_id = @publication.bibtex_entry.entry_type

    @author_options = []

    @bibtype_fields = BibtexEntryType.fields(@selected_bibtex_entry_type_id)
  end

  def update
    @publication = Publication.find(params[:id])
    @author_options = []

    if @publication.update_attributes(params[:publication])
      flash[:notice] = "Successfully Updated Publication."

      # expires the previosly cached entries
      Rails.cache.delete "publication-#{@publication.id}-ieee"
      Rails.cache.delete "publication-#{@publication.id}-bibtex"

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

  def autocomplete_for_project
    @publication = Publication.find(params[:id])

    @projects = Project.active.like(params[:q]).find(:all, :limit => 100) - @publication.projects
    logger.debug "Query for \"#{params[:q]}\" returned \"#{@projects.size}\" results"
    render :layout => false
  end

  # returns an hash with :authors and :users lists
  def suggest_authors(lastname)

    # todo: improve name searching algorithm -- lf.20121127
    authorships = Authorship.like(lastname).find(:all, :limit => 100)
    logger.error { "Suggest Authors: Found #{authorships.count} Authorships " }

    suggested_authors = []
    suggested_authors = authorships.map { |a| a.author } unless authorships.empty?
    suggested_authors.uniq! unless suggested_authors.empty?

    users = User.like(lastname).find(:all)

    suggested_users = users.reject { |u|
      suggested_authors.include?(u.author)
    }

    { :authors => suggested_authors, :users => suggested_users }

  end

  def autocomplete_for_author
    @results = []

    object_id = params[:object_id]
    @object_name = "publications[authorships_attributes][#{object_id}][search_results]"

    users_list = User.active.like(params[:q]).find(:all, :limit => 100)

    authorships_list = Authorship.like(params[:q]).find(:all, :limit => 100)

    # list with authorships that are associated with users
    authorships_with_users = authorships_list.reject { |a| a.author.user.nil? }

    # authorships not associated with a user
    orphan_authorships = authorships_list - authorships_with_users
    authorships_with_users.map! { |a| a.author.user }
    @results = (users_list + authorships_with_users).uniq! + orphan_authorships

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
      format.js {
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
