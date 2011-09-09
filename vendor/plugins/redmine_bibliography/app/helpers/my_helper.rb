module MyHelper

  def get_my_publications()
    if not User.current.author.nil?
      @my_publications = Publication.all(:include => :authors, :conditions => "authors.id = #{User.current.author.id}")
    else
      @my_publications = []
    end
  end 

  def render_publications_projects(publication)    
    s = ""
    projs = []
    
    publication.projects.each do |proj|
      projs << link_to(proj.name, proj)
    end
    
    s << projs.join(', ')
    
    s
  end

  def render_publications_authors(publication)    
    s = ""
    auths = []
          
    publication.authorships.each do |auth|
      auths << h(auth.name_on_paper)
    end
    
    s << auths.join(', ')

    s
  end


end
