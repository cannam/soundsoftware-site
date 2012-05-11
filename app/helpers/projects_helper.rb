# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module ProjectsHelper
  def link_to_version(version, options = {})
    return '' unless version && version.is_a?(Version)
    link_to_if version.visible?, format_version_name(version), { :controller => 'versions', :action => 'show', :id => version }, options
  end

  def project_settings_tabs
    tabs = [{:name => 'info', :action => :edit_project, :partial => 'projects/edit', :label => :label_information_plural},
            {:name => 'overview', :action => :edit_project, :partial => 'projects/settings/overview', :label => :label_welcome_page},
            {:name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural},
            {:name => 'versions', :action => :manage_versions, :partial => 'projects/settings/versions', :label => :label_version_plural},
            {:name => 'categories', :action => :manage_categories, :partial => 'projects/settings/issue_categories', :label => :label_issue_category_plural},
            {:name => 'wiki', :action => :manage_wiki, :partial => 'projects/settings/wiki', :label => :label_wiki},
            {:name => 'repository', :action => :manage_repository, :partial => 'projects/settings/repository', :label => :label_repository},
            {:name => 'boards', :action => :manage_boards, :partial => 'projects/settings/boards', :label => :label_board_plural},
            {:name => 'activities', :action => :manage_project_activities, :partial => 'projects/settings/activities', :label => :enumeration_activities}
            ]
    tabs.select {|tab| User.current.allowed_to?(tab[:action], @project)}
  end

  def parent_project_select_tag(project)
    selected = project.parent
    # retrieve the requested parent project
    parent_id = (params[:project] && params[:project][:parent_id]) || params[:parent_id]
    if parent_id
      selected = (parent_id.blank? ? nil : Project.find(parent_id))
    end

    options = ''
    options << "<option value=''></option>" if project.allowed_parents.include?(nil)
    options << project_tree_options_for_select(project.allowed_parents.compact, :selected => selected)
    content_tag('select', options.html_safe, :name => 'project[parent_id]', :id => 'project_parent_id')
  end

  def render_project_short_description(project)
    s = ''
    if (project.short_description)
      s << "<div class='description'>"
      s << textilizable(project.short_description, :project => project).gsub(/<[^>]+>/, '')
      s << "</div>"
    end
    s
  end
  
  # Renders a tree of projects as a nested set of unordered lists
  # The given collection may be a subset of the whole project tree
  # (eg. some intermediate nodes are private and can not be seen)
  def render_project_hierarchy(projects)
    s = ''
    if projects.any?
      ancestors = []
      original_project = @project
      projects.each do |project|
        # set the project environment to please macros.
        @project = project
        if (ancestors.empty? || project.is_descendant_of?(ancestors.last))
          s << "<ul class='projects #{ ancestors.empty? ? 'root' : nil}'>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        classes = (ancestors.empty? ? 'root' : 'child')
        s << "<li class='#{classes}'><div class='#{classes}'>" +
               link_to_project(project, {}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}")
        s << render_project_short_description(project)
        s << "</div>\n"
        ancestors << project
      end
      s << ("</li></ul>\n" * ancestors.size)
      @project = original_project
    end
    s.html_safe
  end


  def render_my_project_in_hierarchy(project)
 
    s = ''

    if User.current.member_of?(project)

      # set the project environment to please macros.
      @project = project

      classes = (project.root? ? 'root' : 'child')
      
      s << "<li class='#{classes}'><div class='#{classes}'>" +
        link_to_project(project, {}, :class => "project my-project")
      if project.is_public?
        s << " <span class='public'>" << l("field_is_public") << "</span>"
      else
        s << " <span class='private'>" << l("field_is_private") << "</span>"
      end
      s << render_project_short_description(project)
      s << "</div>\n"

      cs = ''
      project.children.each do |child|
        cs << render_my_project_in_hierarchy(child)
      end

      if cs != ''
        s << "<ul class='projects'>\n" << cs << "</ul>\n";
      end

    end

    s

  end

  # Renders a tree of projects where the current user belongs
  # as a nested set of unordered lists
  # The given collection may be a subset of the whole project tree
  # (eg. some intermediate nodes are private and can not be seen)
  def render_my_project_hierarchy(projects)

    s = ''

    original_project = @project

    projects.each do |project|
      if project.root? || !projects.include?(project.parent)
        s << render_my_project_in_hierarchy(project)
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

  # Renders a tree of projects that the current user does not belong
  # to, or of all projects if the current user is not logged in.  The
  # given collection may be a subset of the whole project tree
  # (eg. some intermediate nodes are private and can not be seen).  We
  # are potentially interested in various things: the project name,
  # description, manager(s), creation date, last activity date,
  # general activity level, whether there is anything actually hosted
  # here for the project, etc.
  def render_project_table(projects)

    s = ""
    s << "<div class='autoscroll'>"
    s << "<table class='list projects'>"
    s << "<thead><tr>"
    
    s << sort_header_tag('name', :caption => l("field_name"))
    s << "<th class='managers'>" << l("label_managers") << "</th>"
    s << sort_header_tag('created_on', :default_order => 'desc')
    s << sort_header_tag('updated_on', :default_order => 'desc')

    s << "</tr></thead><tbody>"

    original_project = @project

    projects.each do |project|
      s << render_project_in_table(project, cycle('odd', 'even'), 0)
    end

    s << "</table>"

    @project = original_project

    s
  end


  def render_project_in_table(project, oddeven, level)

    # set the project environment to please macros.
    @project = project

    classes = (level == 0 ? 'root' : 'child')

    s = ""
    
    s << "<tr class='#{oddeven} #{classes} level#{level}'>"
    s << "<td class='firstcol' align=top><div class='name hosted_here"
    s << " no_description" if project.description.blank?
    s << "'>" << link_to_project(project, {}, :class => "project #{User.current.member_of?(project) ? 'my-project' : nil}");
    s << "</div>"
    s << render_project_short_description(project)
      
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
        s << render_project_in_table(child, oddeven, level + 1)
      end
    end
    
    s
  end


  # Returns a set of options for a select field, grouped by project.
  def version_options_for_select(versions, selected=nil)
    grouped = Hash.new {|h,k| h[k] = []}
    versions.each do |version|
      grouped[version.project.name] << [version.name, version.id]
    end
    # Add in the selected
    if selected && !versions.include?(selected)
      grouped[selected.project.name] << [selected.name, selected.id]
    end

    if grouped.keys.size > 1
      grouped_options_for_select(grouped, selected && selected.id)
    else
      options_for_select((grouped.values.first || []), selected && selected.id)
    end
  end

  def format_version_sharing(sharing)
    sharing = 'none' unless Version::VERSION_SHARINGS.include?(sharing)
    l("label_version_sharing_#{sharing}")
  end
end
