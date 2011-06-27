ActionController::Routing::Routes.draw do |map|
  map.resources :publications, :collection => { :sort_authors => :post }
end