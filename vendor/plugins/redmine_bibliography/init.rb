require 'redmine'

Redmine::Plugin.register :redmine_bibliography do
  name 'Redmine Bibliography plugin'
  author 'Chris Cannam, Luis Figueira'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  
  permission :view_bibliography, :redmine_bibliography => :index

  menu :project_menu, :redmine_bibliography, {:controller  => 'publications', :action => 'index'}, :caption  => 'Bibliography', :after => :activity, :param => :project_id
  
end

