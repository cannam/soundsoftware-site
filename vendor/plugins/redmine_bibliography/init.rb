require 'redmine'
require 'dispatcher'

RAILS_DEFAULT_LOGGER.info 'Starting Bibliography Plugin for RedMine'

# Patches to the Redmine core.
Dispatcher.to_prepare :redmine_model_dependencies do
  require_dependency 'project'
  require_dependency 'user'

  unless Project.included_modules.include? Bibliography::ProjectPublicationsPatch
    Project.send(:include, Bibliography::ProjectPublicationsPatch)
  end

  unless Project.included_modules.include? Bibliography::UserAuthorPatch
    Project.send(:include, Bibliography::UserAuthorPatch)
  end

end


# Plugin Info
Redmine::Plugin.register :redmine_bibliography do
  name 'Redmine Bibliography plugin'
  author 'Chris Cannam, Luis Figueira'
  description 'This is a bibliography management plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'

  settings :default => { 'menu' => 'Bibliography' }, :partial => 'settings/bibliography'

  project_module :redmine_bibliography do
    permission :publications, { :publications => :index }, :public => true
    permission :edit_redmine_bibliography, {:redmine_bibliography => [:edit, :update]}, :public => true
    permission :add_publication, {:redmine_bibliography => [:new, :create]}, :public => true
  end

  # extending the Project Menu
  menu :project_menu, :publications, { :controller => 'publications', :action => 'index', :path => nil }, :after => :activity, :param => :project_id, :caption => Proc.new { Setting.plugin_redmine_bibliography['menu'] },
   :if => Proc.new { !Setting.plugin_redmine_bibliography['menu'].blank? }
    
end