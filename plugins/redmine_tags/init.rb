# This file is a part of redmine_tags
# redMine plugin, that adds tagging support.
#
# Copyright (c) 2010 Aleksey V Zapparov AKA ixti
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

require 'redmine'
require 'redmine_tags'


Redmine::Plugin.register :redmine_tags do
  name        'redmine_tags'
  author      'Aleksey V Zapparov AKA "ixti"'
  description 'redMine tagging support'
  version     '2.0.1-dev'
  url         'https://github.com/ixti/redmine_tags/'
  author_url  'http://www.ixti.net/'

  requires_redmine :version_or_higher => '1.2.0'

  settings :default => {
    :issues_sidebar => 'none',
    :issues_show_count => 0,
    :issues_open_only => 0,
    :issues_sort_by => 'name',
    :issues_sort_order => 'asc'
  }, :partial => 'tags/settings'
end


ActionDispatch::Callbacks.to_prepare do
  require_dependency 'redmine_project_filtering'

  unless Project.included_modules.include?(RedmineTags::Patches::ProjectPatch)
    Project.send(:include, RedmineTags::Patches::ProjectPatch)
  end

  unless ProjectsHelper.included_modules.include?(RedmineTags::Patches::ProjectsHelperPatch)
    ProjectsHelper.send(:include, RedmineTags::Patches::ProjectsHelperPatch)
  end

  unless Issue.included_modules.include?(RedmineTags::Patches::IssuePatch)
    Issue.send(:include, RedmineTags::Patches::IssuePatch)
  end

  unless IssuesHelper.included_modules.include?(RedmineTags::Patches::IssuesHelperPatch)
    IssuesHelper.send(:include, RedmineTags::Patches::IssuesHelperPatch)
  end

  unless ProjectsController.included_modules.include?(RedmineTags::Patches::ProjectsControllerPatch)
    ProjectsController.send(:include, RedmineTags::Patches::ProjectsControllerPatch)
  end

  unless AutoCompletesController.included_modules.include?(RedmineTags::Patches::AutoCompletesControllerPatch)
    AutoCompletesController.send(:include, RedmineTags::Patches::AutoCompletesControllerPatch)
  end

  unless Query.included_modules.include?(RedmineTags::Patches::QueryPatch)
    Query.send(:include, RedmineTags::Patches::QueryPatch)
  end

  unless QueriesHelper.included_modules.include?(RedmineTags::Patches::QueriesHelperPatch)
    QueriesHelper.send(:include, RedmineTags::Patches::QueriesHelperPatch)
  end
end


require 'redmine_tags/hooks/model_issue_hook'
require 'redmine_tags/hooks/views_issues_hook'
require 'redmine_tags/hooks/views_projects_hook'

