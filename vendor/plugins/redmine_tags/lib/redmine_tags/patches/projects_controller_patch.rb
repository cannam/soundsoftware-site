require_dependency 'projects_controller'

module RedmineTags
  module Patches
    module ProjectsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do          
          unloadable 
          before_filter :add_tags_to_project, :only => [:save, :update]
          before_filter :filter_projects, :only => :index                
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
  
  
         def calculate_project_filtering_settings
            @project_filtering_settings = Setting[:plugin_redmine_project_filtering]
          end

          def filter_projects
            logger.error { "before_filter: filter_projects" }

            @project = Project.new
                                  
            respond_to do |format|
              format.any(:html, :xml) { 
                calculate_filtered_projects
              }
              format.js {
                calculate_filtered_projects
                render :update do |page|
                  page.replace_html 'projects', :partial => 'filtered_projects'
                end
              }
              format.atom {
                projects = Project.visible.find(:all, :order => 'created_on DESC',
                                                      :limit => Setting.feeds_limit.to_i)
                render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
              }
            end
          end

          private

          def calculate_filtered_projects

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
            
            # intersection of both prject groups            
            @projects = @projects && @tagged_projects_ids unless @tag_list.empty?
            
            # luisf: what exactly are the featured projects? could they be "my projects"?
            @featured_projects = @featured_projects.search_by_question(@question) if @featured_projects

          end
  
  
  
        
      end
    end
  end
end
