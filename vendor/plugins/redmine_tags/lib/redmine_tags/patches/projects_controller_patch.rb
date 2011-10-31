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
#          debugger
          logger.error { "TAG_LIST-->#{params[:project][:tag_list]}" }
        end
      end
    end
  end
end




