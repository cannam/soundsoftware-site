RedmineApp::Application.routes.draw do
  match '/issue_tags/auto_complete/:project_id', :to => 'auto_completes#issue_tags', :via => :get, :as => 'auto_complete_issue_tags'
  match '/auto_completes/project_search_tags', :to => 'auto_completes#project_search_tags'
  match '/auto_completes/project_tags', :to => 'auto_completes#project_tags'
  match 'projects/set_fieldset_status' => 'projects#set_fieldset_status', :constraints => {:method => :post}
end
