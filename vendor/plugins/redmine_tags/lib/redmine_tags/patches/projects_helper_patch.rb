module RedmineTags
  module Patches
    module ProjectsHelperPatch

      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)
        base.send(:include, TagsHelper)
        base.class_eval do
          unloadable
        end
      end

      module InstanceMethods        
        # Renders a tree of projects that the current user does not belong
        # to, or of all projects if the current user is not logged in.  The
        # given collection may be a subset of the whole project tree
        # (eg. some intermediate nodes are private and can not be seen).  We
        # are potentially interested in various things: the project name,
        # description, manager(s), creation date, last activity date,
        # general activity level, whether there is anything actually hosted
        # here for the project, etc.
        def render_project_table_with_filtering(projects, question)          
          custom_fields = ""
          s = ""
          if projects.any?
            tokens = RedmineProjectFiltering.calculate_tokens(question, custom_fields)
            
            s << "<div class='autoscroll'>"
            s << "<table class='list projects'>"
            s << "<thead><tr>"
        
            s << sort_header_tag('name', :caption => l("field_name"))
            s << "<th class='tags'>" << l("tags") << "</th>"
            s << "<th class='managers'>" << l("label_managers") << "</th>"
            s << sort_header_tag('created_on', :default_order => 'desc')
            s << sort_header_tag('updated_on', :default_order => 'desc')
        
            s << "</tr></thead><tbody>"
        
            original_project = @project
        
            projects.each do |project|
              s << render_project_in_table_with_filtering(project, cycle('odd', 'even'), 0, tokens)
            end
        
            s << "</table>"
          else
            s << "\n"
          end
          @project = original_project

          s
        end

        def render_project_in_table_with_filtering(project, oddeven, level, tokens)          
          # set the project environment to please macros.
          @project = project

          classes = (level == 0 ? 'root' : 'child')

          s = ""

          s << "<tr class='#{oddeven} #{classes} level#{level}'>"
          s << "<td class='firstcol' align=top><div class='name hosted_here"
          s << " no_description" if project.description.blank?
          s << "'>" << link_to( highlight_tokens(project.name, tokens), {:controller => 'projects', :action => 'show', :id => project}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}")
          s << "</div>"
          s << highlight_tokens(render_project_short_description(project), tokens)
          s << "</td>"

          # taglist
          s << "<td class='tags' align=top>" << project.tag_counts.collect{ |t| render_project_tag_link(t) }.join(', ') << "</td>"

          s << "<td class='managers' align=top>"
           
          u = project.users_by_role
          if u
            u.keys.each do |r|
              if r.allowed_to?(:edit_project)
                mgrs = []
                u[r].sort.each do |m|
                  mgrs << link_to_user(m)
                end
                if mgrs.size < 3
                  s << '<nobr>' << mgrs.join(', ') << '</nobr>'
                else
                  s << mgrs.join(', ')
                end
              end
            end
          end

          s << "</td>"
          
          s << "<td class='created_on' align=top>" << format_date(project.created_on) << "</td>"
          s << "<td class='updated_on' align=top>" << format_date(project.updated_on) << "</td>"

          s << "</tr>"

          project.children.each do |child|
            if child.is_public? or User.current.member_of?(child)
              s << render_project_in_table_with_filtering(child, oddeven, level + 1, tokens)
            end
          end

          s
        end
        
        
        
        # Renders a tree of projects as a nested set of unordered lists
        # The given collection may be a subset of the whole project tree
        # (eg. some intermediate nodes are private and can not be seen)
        def render_project_hierarchy_with_filtering(projects,custom_fields,question)
          s = []
          if projects.any?
            tokens = RedmineProjectFiltering.calculate_tokens(question, custom_fields)
            debugger
            

            ancestors = []
            original_project = @project
            projects.each do |project|
              # set the project environment to please macros.
              @project = project
              if (ancestors.empty? || project.is_descendant_of?(ancestors.last))
                s << "<ul class='projects #{ ancestors.empty? ? 'root' : nil}'>"
              else
                ancestors.pop
                s << "</li>"
                while (ancestors.any? && !project.is_descendant_of?(ancestors.last)) 
                  ancestors.pop
                  s << "</ul></li>"
                end
              end
              classes = (ancestors.empty? ? 'root' : 'child')
              s << "<li class='#{classes}'><div class='#{classes}'>" +
                link_to( highlight_tokens(project.name, tokens), 
                  {:controller => 'projects', :action => 'show', :id => project},
                  :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}"
                )
              s << "<ul class='filter_fields'>"

           #  CustomField.usable_for_project_filtering.each do |field|
           #    value_model = project.custom_value_for(field.id)
           #    value = value_model.present? ? value_model.value : nil
           #    s << "<li><b>#{field.name.humanize}:</b> #{highlight_tokens(value, tokens)}</li>" if value.present?
           #  end
              
              s << "</ul>"
              s << "<div class='clear'></div>"
              unless project.description.blank?
                s << "<div class='wiki description'>"
                s << "<b>#{ t(:field_description) }:</b>"
                s << highlight_tokens(textilizable(project.short_description, :project => project), tokens)
                s << "\n</div>"
              end
              s << "</div>"
              ancestors << project
            end
            ancestors.size.times{ s << "</li></ul>" }
            @project = original_project
          end
          s.join "\n"
        end
        
        # Renders a tree of projects where the current user belongs
        # as a nested set of unordered lists
        # The given collection may be a subset of the whole project tree
        # (eg. some intermediate nodes are private and can not be seen)
        def render_my_project_hierarchy_with_tags(projects)

          s = ''

          original_project = @project

          projects.each do |project|
            if project.root? || !projects.include?(project.parent)
              s << render_my_project_in_hierarchy_with_tags(project)
            end
          end

          @project = original_project

          if s != ''
            a = ''
            a << "<ul class='projects root'>\n"
            a << s
            a << "</ul>\n"
            s = a
          end

          s

        end
        
        
        

        def render_my_project_in_hierarchy_with_tags(project)

          s = ''

          if User.current.member_of?(project)

            # set the project environment to please macros.
            @project = project

            classes = (project.root? ? 'root' : 'child')

            s << "<li class='#{classes}'><div class='#{classes}'>" +
              link_to_project(project, {}, :class => "project my-project")
            if project.is_public?
              s << " <span class='public'>" << l(:field_is_public) << "</span>"
            else
              s << " <span class='private'>" << l(:field_is_private) << "</span>"
            end
           
            tc = project.tag_counts
            if tc.empty?
              s << " <span class='no-tags'>" << l(:field_no_tags) << "</span>"
            else
              s << " <span class='tags'>" << tc.collect{ |t| render_project_tag_link(t) }.join(', ') << "</span>"
            end

            s << render_project_short_description(project)

            s << "</div>\n"

            cs = ''
            project.children.each do |child|
              cs << render_my_project_in_hierarchy_with_tags(child)
            end

            if cs != ''
              s << "<ul class='projects'>\n" << cs << "</ul>\n";
            end

          end

          s

        end

        
        
        private
        
        # copied from search_helper. This one doesn't escape html or limit the text length
        def highlight_tokens(text, tokens)
          return text unless text && tokens && !tokens.empty?
          re_tokens = tokens.collect {|t| Regexp.escape(t)}
          regexp = Regexp.new "(#{re_tokens.join('|')})", Regexp::IGNORECASE    
          result = ''
          text.split(regexp).each_with_index do |words, i|
            words = words.mb_chars
            if i.even?
              result << words
            else
              t = (tokens.index(words.downcase) || 0) % 4
              result << content_tag('span', words, :class => "highlight token-#{t}")
            end
          end
          result
        end
      
      end
    end
  end
end

