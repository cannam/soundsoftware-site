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

          attr_accessor :tag_list
          acts_as_taggable

        end
      end

      module InstanceMethods
      end

      module ClassMethods
        def search_by_question(question)
          if question.length > 1
            search(RedmineProjectFiltering.calculate_tokens(question), nil, :all_words => true).first.sort_by(&:lft)
          else
            all(:order => 'lft')
          end
        end


        # Returns available project tags
        #  does not show tags from private projects
        def available_tags( options = {} )

          name_like = options[:name_like]
          options = {}
          visible   = ARCondition.new

          visible << ["#{Project.table_name}.is_public = '1'"]

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
