RedmineApp::Application.routes.draw do
  resources :publications

  match "publications/show_bibtex_fields", :to => 'publications#show_bibtex_fields'


end