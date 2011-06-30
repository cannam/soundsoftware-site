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
    link_to_function(author.name, "console.log($(this).up('div').up('div').select('input[id$=name_on_paper]'))")
  end
  
  def choose_author_link(name, authors)
    s = ''
    authors.sort.each do |author|
      s << "#{identify_author author}\n"
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
end
