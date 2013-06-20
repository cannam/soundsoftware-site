module Bibliography
  module ProjectsHelperPatch

    def self.included(base) # :nodoc:
      base.send(:include, InstanceMethods)
      base.send(:include, PublicationsHelper)

      base.class_eval do
        unloadable
      end
    end

    module InstanceMethods
    end
  end
end

