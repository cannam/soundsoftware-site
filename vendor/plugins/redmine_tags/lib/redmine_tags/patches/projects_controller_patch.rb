require_dependency 'projects_controller'

module RedmineTags
  module Patches
    module ProjectsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do          
          unloadable 
          before_filter :add_tags_to_project, :only => [:save, :update]
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
      end
    end
  end
end
