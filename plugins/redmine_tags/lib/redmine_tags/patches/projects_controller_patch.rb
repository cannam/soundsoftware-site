# -*- coding: utf-8 -*-
require_dependency 'projects_controller'

module RedmineTags
  module Patches
    module ProjectsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          # skip_before_filter :authorize, :only => [:set_fieldset_status]
          # skip_before_filter :find_project, :only => [:set_fieldset_status]

          alias :index filtered_index
        end
      end

      module InstanceMethods
        def paginate_projects
          sort_init 'name'
          sort_update %w(name lft created_on updated_on)
          @limit = per_page_option

          # Only top-level visible projects are counted --lf.10Jan2013
          top_level_visible_projects = @projects.visible_roots
          @project_count = top_level_visible_projects.count

          # Project.visible_roots.find(@projects).count

          @project_pages = Redmine::Pagination::Paginator.new @project_count, @limit, params['page']
          @offset ||= @project_pages.current.offset
        end

        # Lists visible projects. Paginator is for top-level projects only
        # (subprojects belong to them)
        def filtered_index
          @project = Project.new
          filter_projects
          # get_fieldset_statuses

          sort_clause = "name"

          respond_to do |format|
            format.html {
              paginate_projects

              # todo: check ordering ~luisf.14/Jan/2013
              @projects = @projects[@offset, @limit]

              render :template => 'projects/index.html.erb', :layout => !request.xhr?
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
          # find projects like question
          @question = (params[:search] || "").strip

          if @question.empty?
            projects = Project.visible
          else
            projects = Project.visible.like(@question)
          end

          # search for tags
          if params.has_key?(:tag_search)
             tag_list = (params[:tag_search] || "").strip.split(",")
          else
             tag_list = ""
          end

          unless tag_list.empty?
            projects = projects.tagged_with(tag_list)
          end

          ## TODO: luisf-10Apr2013 should I only return the visible_roots?
          @projects = projects

        end
      end
    end
  end
end
