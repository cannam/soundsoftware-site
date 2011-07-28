require 'bibtex'

module PublicationsHelper
  def projects_check_box_tags(name, projects)
    s = ''
    projects.sort.each do |project|
      s << "<label>#{ check_box_tag name, project.id, false } #{link_to_project project}</label>\n"
    end
    s 
  end
  
  def identify_author(author)
    if author.class == User      
      author_info = {
        :name_on_paper => author.name,
        :user_id => author.id
      }
    
    else 
      if author.class == Author    
      author_info = { 
        :name_on_paper => author.name, 
        :user_id => author.user_id,
        :id => author.id
      }
      end
    end
                
    link_to_function(author.name, "update_author_info(this," + author_info.to_json + ")")
  end
  
  def choose_author_link(name, authors_users)
    s = ''
    authors_users.sort.each do |author_user|
      s << "#{identify_author author_user}\n"
    end
    s 
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end
    
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end    
    link_to_function(name, h("add_fields(this, '#{association}', '#{escape_javascript(fields)}')"), { :class => 'icon icon-add', :id => "add_another_author" })
  end  

  def sanitized_object_name(object_name)
    object_name.gsub(/\]\[|[^-a-zA-Z0-9:.]/,"_").sub(/_$/,"")
  end

  def sanitized_method_name(method_name)
    method_name.sub(/\?$/, "")
  end

  def form_tag_id(object_name, method_name)    
    str = "#{sanitized_object_name(object_name.to_s)}_#{sanitized_method_name(method_name.to_s)}"
    str.to_sym
  end
  
  def render_projects_list(publication)
    s = ""
    projs = []
    
    publication.projects.each do |proj|
      projs << link_to_project(proj)
    end
    
    if projs.size < 3
      s << '<nobr>' << projs.join(', ') << '</nobr>'
    else
      s << projs.join(', ')
    end
    s
  end
  

end

