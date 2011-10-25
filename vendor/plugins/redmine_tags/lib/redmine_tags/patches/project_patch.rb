# C4DM

require_dependency 'project'

module RedmineTags
  module Patches
    module ProjectPatch
      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          unloadable
          acts_as_taggable
        end
      end

      module ClassMethods
        # Returns available issue tags
        # === Parameters
        # * <i>options</i> = (optional) Options hash of
        #   * project   - Project to search in.
        #   * open_only - Boolean. Whenever search within open issues only.
        #   * name_like - String. Substring to filter found tags.
        def available_tags(options = {})
          project   = options[:project]
          open_only = options[:open_only]
          name_like = options[:name_like]
          options   = {}
          visible   = ARCondition.new
          
          if project
            project = project.id if project.is_a? Project
            visible << ["#{Issue.table_name}.project_id = ?", project]
          end

          if open_only
            visible << ["#{Issue.table_name}.status_id IN " +
                        "( SELECT issue_status.id " + 
                        "    FROM #{IssueStatus.table_name} issue_status " +
                        "   WHERE issue_status.is_closed = ? )", false]
          end

          if name_like
            visible << ["#{ActsAsTaggableOn::Tag.table_name}.name LIKE ?", "%#{name_like.downcase}%"]
          end

          options[:conditions] = visible.conditions
          self.all_tag_counts(options)
        end
      end
    end
  end
end
