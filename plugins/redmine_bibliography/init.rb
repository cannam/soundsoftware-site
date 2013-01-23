require 'redmine'

require 'bibtex'
require 'citeproc'

# Patches to the Redmine core.
ActionDispatch::Callbacks.to_prepare do
  require_dependency 'project'
  require_dependency 'user'
  require_dependency 'mailer'

  unless Project.included_modules.include? Bibliography::ProjectPublicationsPatch
    Project.send(:include, Bibliography::ProjectPublicationsPatch)
  end

  unless User.included_modules.include? Bibliography::UserAuthorPatch
    User.send(:include, Bibliography::UserAuthorPatch)
  end

  unless Mailer.included_modules.include? Bibliography::MailerPatch
    Mailer.send(:include, Bibliography::MailerPatch)
  end

  unless ProjectsHelper.included_modules.include?(Bibliography::ProjectsHelperPatch)
    ProjectsHelper.send(:include, Bibliography::ProjectsHelperPatch)
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

  settings :default => { 'menu' => 'Publications' }, :partial => 'settings/bibliography'

  project_module :redmine_bibliography do
    permission :view_publication, {:publications => :show}, :public => :true
    permission :publications, { :publications => :index }, :public => true
    permission :edit_publication, {:publications => [:edit, :update]}
    permission :add_publication, {:publications => [:new, :create]}
    permission :delete_publication, {:publications => :destroy}


  end

  # extending the Project Menu
  menu :project_menu, :publications, { :controller => 'publications', :action => 'index', :path => nil }, :after => :activity, :param => :project_id, :caption => Proc.new { Setting.plugin_redmine_bibliography['menu'] },
   :if => Proc.new { !Setting.plugin_redmine_bibliography['menu'].blank? }

  activity_provider :publication, :class_name => 'Publication', :default => true

end



