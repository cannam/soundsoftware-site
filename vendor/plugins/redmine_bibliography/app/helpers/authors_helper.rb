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
  
end
