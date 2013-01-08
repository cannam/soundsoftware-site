RedmineApp::Application.routes.draw do
  map.connect 'projects/set_fieldset_status', :controller => 'projects', :action => 'set_fieldset_status', :conditions => {:method => :post}
end