require 'bibtex'

module PublicationsHelper
  def projects_check_box_tags(name, projects)
    s = ''
    projects.sort.each do |project|
      s << "<label>#{ check_box_tag name, project.id, false } #{link_to_project project}</label>\n"
    end
    s 
  end
  
  def choose_author_link(object_name, items)
    # called by autocomplete_for_author (publications' action/view)
    # creates the select list based on the results array
    # results is an array with both Users and Authorships objects
        
    @author_options = []
    @results.each do |result|
      @author_options << ["#{result.name} (#{result.mail})", "#{result.class.to_s}_#{result.id.to_s}"]
    end
    
   if @results.size > 0
     s = select_tag( form_tag_name(object_name, :author_search_results), options_for_select(@author_options), { :id => form_tag_id(object_name, :author_search_results), :size => 3} )
     s << observe_field( form_tag_id(object_name, :author_search_results), :on => 'click', :function => "alert('Element changed')", :with => 'q')
   else
     s = "<em>No Authors found that match your search… sorry!</em>"
   end      
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", :class => 'icon icon-del')
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
  
  def form_tag_name(object_name, method_name)
      str = "#{object_name.to_s}[#{sanitized_method_name(method_name.to_s)}]"
      str.to_sym 
  end
  
  def form_tag_id(object_name, method_name)    
    str = "#{sanitized_object_name(object_name.to_s)}_#{sanitized_method_name(method_name.to_s)}"
    str.to_sym
  end
  
  def form_object_id(object_name)
    str = object_name.split("\[").last().gsub("\]","")
    str.to_sym
  end
  
  def render_projects_list(publication)
    logger.error { "PROJECT NAME #{@project.name unless @project.nil?}" }
    
    s = ""

    publication.projects.each do |proj|
      if @project == proj
        confirm_msg = "Are you sure you want to remove the current project from this publication's projects list?"
      else
        confirm_msg = false
      end 
      
      s << link_to_project(proj) + link_to_remote(l(:button_delete), { :url => { :controller => 'publications', :action => 'remove_project', :id => publication, :remove_project_id => proj,  :project_id => @project }, :method => :post, :confirm => confirm_msg }, :class => 'icon icon-del') + "<br />"
    end
    
    s  
  end
  
  def show_bibtex_fields(bibtex_entry)
    s = ""

    bibtex_entry.attributes.each do |field|
      if field[1] != nil
        s << "<h4>" + l("field_#{field[0]}") + "</h4>" 

        if field[0] == "entry_type"
          s << bibtex_entry.entry_type_label
        else
          s << bibtex_entry.attributes[field[0]].to_s
        end
      end
    end
    s
  end 
end

