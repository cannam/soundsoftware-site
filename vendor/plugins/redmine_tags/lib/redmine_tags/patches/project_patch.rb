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

      def before_save_with_save_tags()
#        debugger
        logger.error { "GONNA SAVE TAG LIST" }


#        params[:tag_list]
        
        
        # logger.error { @project.name }

    #    if params && params[:project] && !params[:project][:tag_list].nil?
    #      old_tags = context[:project].tag_list.to_s
    #      context[:project].tag_list = params[:project][:tag_list]
    #      new_tags = context[:project].tag_list.to_s
    #
    #      unless (old_tags == new_tags || context[:project].current_journal.blank?)
    #        context[:project].current_journal.details << JournalDetail.new(:property => 'attr',
    #                                                                     :prop_key => 'tag_list',
    #                                                                     :old_value => old_tags,
    #                                                                     :value => new_tags)
    #      end
    #    end
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
            visible << ["#{Project.table_name}.status_id IN " +
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
