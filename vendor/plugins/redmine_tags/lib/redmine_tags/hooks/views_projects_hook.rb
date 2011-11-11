module RedmineTags
  module Hooks
    class ViewsProjectsHook < Redmine::Hook::ViewListener
      render_on :view_projects_form, :partial => 'projects/tags_form'
      render_on :view_projects_show_left, :partial => 'projects/tags'
#      render_on :view_issues_sidebar_planning_bottom, :partial => 'issues/tags_sidebar'
    end
  end
end

