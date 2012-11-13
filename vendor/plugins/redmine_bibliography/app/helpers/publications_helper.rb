# -*- coding: utf-8 -*-
require 'bibtex'

module PublicationsHelper
  include AuthorshipsHelper

  def create_publication_tabs
    tabs = [{:name => 'default', :partial => 'publications/new/default', :label => :label_default},
            {:name => 'bibtex', :partial => 'publications/new/bibtex', :label => :label_bibtex},
          ]
  end

  def link_to_publication(publication, options={}, html_options = nil)
    url = {:controller => 'publications', :action => 'show', :id => publication}.merge(options)
    link_to(h(publication.title), url, html_options)
  end

  def projects_check_box_tags(name, projects)
    s = ''
    projects.sort.each do |project|
      if User.current.allowed_to?(:edit_publication, project)
        s << "<label>#{ check_box_tag name, project.id, false } #{link_to_project project}</label>\n"
        s << '<br />'
      end
    end

    s
  end

  def choose_author_link(object_name, items)
    # called by autocomplete_for_author (publications' action/view)
    # creates the select list based on the results array
    # results is an array with both Users and Authorships objects

    @author_options = []
    @results.each do |result|
      email_bit = result.mail.partition('@')[2]
      if email_bit != "":
          email_bit = "(@#{email_bit})"
      end
      @author_options << ["#{result.name} #{email_bit}", "#{result.class.to_s}_#{result.id.to_s}"]
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

  def link_to_add_author_fields(name, f, association, action)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, h("add_author_fields(this, '#{association}', '#{escape_javascript(fields)}', '#{action}')"), { :class => 'icon icon-add', :id => "add_another_author" })
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

  def render_authorships_list(publication)
    s = '<p>'

    publication.authorships.each do |authorship|
      s << link_to_authorship(authorship)
      s << "<br /><em>#{authorship.institution}</em></p>"
    end

    s
  end

  def render_projects_list(publication, show_delete_icon)
    s= ""

    publication.projects.visible.each do |proj|
      s << link_to_project(proj, {}, :class => 'publication_project')

      if show_delete_icon
        if User.current.allowed_to?(:edit_publication, @project)
          if @project == proj
            # todo: move this message to yml file
            confirm_msg = 'Are you sure you want to remove the current project from this publication\'s projects list?'
          else
            confirm_msg = false
          end

          s << link_to_remote(l(:button_delete), { :url => { :controller => 'publications', :action => 'remove_project', :id => publication, :remove_project_id => proj,  :project_id => @project }, :method => :post, :confirm => confirm_msg }, :class => 'icon icon-del')
        end
      end

      s << "<br />"
    end

    s
  end

  def show_cite_proc_entry(publication)
    # code that should be moved either to the model or to the controller?

    publication.print_entry(:ieee)
  end

  def print_bibtex_entry(publication)
    publication.print_entry(:bibtex)
  end


  def show_bibtex_fields(bibtex_entry)
    s = ""
    bibtex_entry.attributes.keys.sort.each do |key|
      value = bibtex_entry.attributes[key].to_s
      next if key == 'id' or key == 'publication_id' or value == ""
      s << "<h4>" + l("field_#{key}") + "</h4>"
      s << "<p>"
      if key == "entry_type"
        s << bibtex_entry.entry_type_label
      else
        s << value
      end
      s << "</p>"
    end
    s
  end
end

