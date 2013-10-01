# -*- coding: utf-8 -*-
require 'bibtex'

module PublicationsHelper
  include AuthorshipsHelper

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

    s.html_safe
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)", :class => 'icon icon-del')
  end

  def link_to_add_author_fields(name, f, association, action)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      # renders _authorship_fields.html.erb
      render(association.to_s.singularize + "_fields", :f => builder)
    end

    link_to_function(name, "add_author_fields(this, '#{association}', '#{escape_javascript(fields)}', '#{action}')", { :class => 'icon icon-add', :id => "add_another_author" })
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

    s.html_safe
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

          s << link_to(l(:button_delete), { :url => { :controller => 'publications', :action => 'remove_project', :id => publication, :remove_project_id => proj,  :project_id => @project }, :method => :post, :confirm => confirm_msg }, :class => 'icon icon-del', :remote => :true)
        end
      end

      s << "<br />"
    end

    s.html_safe
  end

  def print_ieee_format(publication)
    Rails.cache.fetch("publication-#{publication.id}-ieee") do
      publication.print_entry(:ieee).html_safe
    end
  end

  def print_bibtex_format(publication)
    Rails.cache.fetch("publication-#{publication.id}-bibtex") do
      publication.print_entry(:bibtex)
    end
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


def render_authorship_link(link_class, link_id)

  # Renders a link for an author used when adding authors for a publication
  # link_class can be either User or Author
  # link_id will be the id of the Author/User we wish to link

  s= ""

  if link_class == "Author"
    s << link_to_author(Author.find(link_id), {}, :class => 'author_link')
  else
    s << link_to_user(User.find(link_id), :class => 'publication_project')
  end

  confirm_msg = "Are you sure you want to remove the link between this publication's author and this code.soundsoftware.ac.uk site user?"

  ## s << link_to(l(:button_delete), { :url => { :controller => 'publications', :action => 'remove_project', :id => publication, :remove_project_id => proj,  :project_id => @project }, :method => :post, :confirm => confirm_msg }, :class => 'icon icon-del', :remote => :true)

  s.html_safe
end

