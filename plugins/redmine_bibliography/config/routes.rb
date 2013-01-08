RedmineApp::Application.routes.draw do |map|
  map.resources :publications, :collection => { :sort_author_order => :post }
end