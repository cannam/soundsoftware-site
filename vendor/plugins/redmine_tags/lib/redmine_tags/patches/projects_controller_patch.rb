require_dependency 'projects_controller'

module RedmineTags
  module Patches
    module ProjectsControllerPatch      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do          
          unloadable 
          skip_before_filter :authorize, :only => [:set_fieldset_status]
          skip_before_filter :find_project, :only => [:set_fieldset_status]
          before_filter :add_tags_to_project, :only => [:save, :update]
#          before_filter :filter_projects, :only => :index

          alias :index filtered_index
        end
      end

      module InstanceMethods
        
        
        
        def add_tags_to_project

          if params && params[:project] && !params[:project][:tag_list].nil?
            old_tags = @project.tag_list.to_s
            new_tags = params[:project][:tag_list].to_s

            unless (old_tags == new_tags)
              @project.tag_list = new_tags
            end
          end
        end

        def paginate_projects
          sort_init 'name'
          sort_update %w(name lft created_on updated_on)
          @limit = per_page_option
          @project_count = Project.visible_roots.find(@projects).count
          @project_pages = ActionController::Pagination::Paginator.new self, @project_count, @limit, params['page']
          @offset ||= @project_pages.current.offset
        end

        def set_fieldset_status

          # luisf. test for missing parameters………
          field = params[:field_id]
          status = params[:status]

          session[(field + "_status").to_sym] = status
          render :nothing => true
        end

        # gets the status of the collabsible fieldsets
        def get_fieldset_statuses
          if session[:my_projects_fieldset_status].nil?
            @myproj_status = "true"
          else
            @myproj_status = session[:my_projects_fieldset_status]
          end
                    
          if session[:filters_fieldset_status].nil?
            @filter_status = "false"
          else
            @filter_status = session[:filters_fieldset_status]
          end                            
        end

        # Lists visible projects. Paginator is for top-level projects only
        # (subprojects belong to them)
        def filtered_index
          @project = Project.new
          filter_projects
          get_fieldset_statuses

          respond_to do |format|
            format.html { 
              paginate_projects
              
              @projects = Project.visible_roots.find(@projects, :offset => @offset, :limit => @limit, :order => sort_clause) 

              if User.current.logged?
                # seems sort_by gives us case-sensitive ordering, which we don't want
                #          @user_projects = User.current.projects.sort_by(&:name)
                @user_projects = User.current.projects.all(:order => :name)
              end
              
              render :template => 'projects/index.rhtml', :layout => !request.xhr?
            }
            format.api {
              @offset, @limit = api_offset_and_limit
              @project_count = Project.visible.count
              @projects = Project.visible.find(@projects, :offset => @offset, :limit => @limit, :order => 'lft')
            }
            format.atom {
              projects = Project.visible.find(:all, :order => 'created_on DESC', :limit => Setting.feeds_limit.to_i)
              render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
            }
            format.js {
              paginate_projects
              @projects = Project.visible_roots.find(@projects, :offset => @offset, :limit => @limit, :order => sort_clause)
              render :update do |page|
                page.replace_html 'projects', :partial => 'filtered_projects'
              end
            }
          end
        end

        private

        def filter_projects                  
          @question = (params[:q] || "").strip     

          if params.has_key?(:project)
            @tag_list = (params[:project][:tag_list] || "").strip.split(",")
          else
            @tag_list = []
          end

          if  @question == ""
            @projects = Project.visible
          else
            @projects = Project.visible.search_by_question(@question)
          end
  
          unless @tag_list.empty?
            @tagged_projects_ids = Project.visible.tagged_with(@tag_list).collect{ |project| Project.find(project.id) }
            @projects = @projects & @tagged_projects_ids
          end
          
          @projects = @projects.collect{ |project| project.root }
          @projects = @projects.uniq

        end
      end
    end
  end
end
