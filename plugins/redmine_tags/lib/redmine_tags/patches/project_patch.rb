# C4DM

require_dependency 'project'

module RedmineTags
  module Patches
    module ProjectPatch
      def self.included(base) # :nodoc:
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable
          acts_as_taggable

          Project.safe_attributes 'tag_list'

          # TODO: review need for this callback (uneeded on update) ~lf.03042013
          after_create :save_tags
        end
      end

      module InstanceMethods
        def save_tags
          self.tags = Tag.transaction do
            @tag_list.each(&:save)
          end
        end
      end

      module ClassMethods
        TAGGING_IDS_LIMIT_SQL = <<-SQL
            tag_id IN (
                SELECT #{ActsAsTaggableOn::Tagging.table_name}.tag_id
                FROM #{ActsAsTaggableOn::Tagging.table_name}
                WHERE #{ActsAsTaggableOn::Tagging.table_name}.taggable_id IN (?)
            )
        SQL

        def search_by_question(question)
          if question.length > 1
            search(RedmineProjectFiltering.calculate_tokens(question), nil, :all_words => true).first.sort_by(&:lft)
          else
            all(:order => 'lft')
          end
        end

        # Returns available project tags
        # Does not return tags from private projects
        # === Parameters
        # * <i>options</i> = (optional) Options hash of
        #   * name_like - String. Substring to filter found tags.
        def available_tags( options = {} )
          ids_scope = Project.visible

          conditions = [""]

          # limit to the tags matching given %name_like%
          if options[:name_like]
            conditions[0] << "#{ActsAsTaggableOn::Tag.table_name}.name LIKE ? AND "
            conditions << "%#{options[:name_like].downcase}%"
          end

          conditions[0] << TAGGING_IDS_LIMIT_SQL
          conditions << ids_scope.map{ |issue| issue.id }.push(-1)

          self.all_tag_counts(:conditions => conditions)
        end
      end
    end
  end
end
