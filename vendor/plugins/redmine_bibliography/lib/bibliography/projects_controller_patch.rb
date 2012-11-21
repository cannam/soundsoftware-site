# -*- coding: utf-8 -*-
require_dependency 'projects_controller'

module Bibliography
    module ProjectsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          # reads the publications helper on the projects controller
          helper :publications
          include PublicationsHelper

        end
      end

      module InstanceMethods

      end

    end
end
