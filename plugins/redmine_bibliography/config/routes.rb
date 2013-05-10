RedmineApp::Application.routes.draw do
  resources :publications

  match "publications/show_bibtex_fields", :to => 'publications#show_bibtex_fields'
  match "publications/autocomplete_for_author", :to => 'publications#autocomplete_for_author'

end