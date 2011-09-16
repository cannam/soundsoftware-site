module AuthorsHelper
  unloadable
  
  def render_author_publications(author)
    s = ""
    pubs = []

    author.publications.each do |pub|
     pubs << link_to(pub.title, pub)
    end

    if pubs.size < 3
      s << '<nobr>' << pubs.join(', ') << '</nobr>'
    else
      s << pubs.join(', ')
    end
    s    
  end
  
  
  # Generates a link to an author
  #   todo: test options
  def link_to_author(author, options={}, html_options = nil)
    url = {:controller => 'authors', :action => 'show', :id => author}.merge(options)
    link_to(h(author.name), url, html_options)
  end

end
