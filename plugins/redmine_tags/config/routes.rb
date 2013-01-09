RedmineApp::Application.routes.draw do
  match 'projects/set_fieldset_status' => 'projects#set_fieldset_status', :constraints => {:method => :post}
end