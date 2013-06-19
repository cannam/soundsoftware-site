RedmineApp::Application.routes.draw do
    match "publications/show_bibtex_fields", :to => 'publications#show_bibtex_fields', :via => "get"

    match "publications/autocomplete_for_author", :to => 'publications#autocomplete_for_author', :via => "get"

    match "authors/show/:id", :to => 'authors#show'

    match "publications/add_project/:id", :to => 'publications#add_project'


    resources :publications
end