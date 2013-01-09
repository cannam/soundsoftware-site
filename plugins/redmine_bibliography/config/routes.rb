RedmineApp::Application.routes.draw do
  resources :publications, :collection => { :sort_author_order => :post }
end