# -*- coding: utf-8 -*-
module AuthorshipsHelper

  # Generates a link to either author or user, depending on which is
  # available
  def link_to_authorship(authorship)
    s = ''
    if authorship.author.nil?
      # legacy reasons…
      s << h(authorship.name_on_paper)
    else
      if authorship.author.user.nil?
        s << link_to(authorship.name_on_paper, :controller => 'authors', :action => 'show', :id => authorship.author)
      else
        s << link_to(authorship.name_on_paper, :controller => 'users', :action => 'show', :id => authorship.author.user)
      end
    end
    s
  end

end
