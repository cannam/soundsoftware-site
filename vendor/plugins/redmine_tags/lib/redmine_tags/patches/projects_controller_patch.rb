require_dependency 'projects_controller'

module RedmineTags
  module Patches
    module ProjectsControllerPatch      
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do          
          unloadable 
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
          @project_count = Project.visible_roots.count
          @project_pages = ActionController::Pagination::Paginator.new self, @project_count, @limit, params['page']
          @offset ||= @project_pages.current.offset          
        end


        # Lists visible projects. Paginator is for top-level projects only
        # (subprojects belong to them)
        def filtered_index
          @project = Project.new
          filter_projects

          respond_to do |format|
            format.html { 
              paginate_projects
              @projects = Project.visible_roots.find(@filtered_projects, :offset => @offset, :limit => @limit, :order => sort_clause) 

              if User.current.logged?
                # seems sort_by gives us case-sensitive ordering, which we don't want
                #          @user_projects = User.current.projects.sort_by(&:name)
                @user_projects = User.current.projects.all(:order => :name)
              end
              
              render :template => 'projects/index.rhtml', :layout => !request.xhr?
            }
            format.api  {
              @offset, @limit = api_offset_and_limit
              @project_count = Project.visible.count
              @projects = Project.visible.find(@filtered_projects, :offset => @offset, :limit => @limit, :order => 'lft')
            }
            format.atom {
              projects = Project.visible.find(:all, :order => 'created_on DESC', :limit => Setting.feeds_limit.to_i)
              render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
            }
            format.js {
              render :update do |page|
                paginate_projects
                @projects = Project.visible_roots.find(@filtered_projects, :offset => @offset, :limit => @limit, :order => sort_clause)
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

          @projects = Project.visible

          @featured_projects = @projects.featured if Project.respond_to? :featured

          # luisf 
          @projects = @projects.search_by_question(@question) unless @question == ""
          @tagged_projects_ids = Project.tagged_with(@tag_list).collect{ |project| Project.find(project.id) } unless @tag_list.empty?

          debugger

          # intersection of both prject groups            
          @projects = @projects && @tagged_projects_ids unless @tag_list.empty?
          
          debugger          
          @filtered_projects = @projects
        end
      end
    end
  end
end
