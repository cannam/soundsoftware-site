# This file is a part of redmine_tags
# redMine plugin, that adds tagging support.
#
# Copyright (c) 2010 Aleksey V Zapparov AKA ixti
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

module TagsHelper
  include ActsAsTaggableOn::TagsHelper
  include FiltersHelper


  # Returns tag link
  # === Parameters
  # * <i>tag</i> = Instance of Tag
  # * <i>options</i> = (optional) Options (override system settings)
  #   * show_count  - Boolean. Whenever show tag counts
  #   * open_only   - Boolean. Whenever link to the filter with "open" issues
  #                   only limit.
  def render_tag_link(tag, options = {})
    filters = [[:tags, '=', tag.name]]
    filters << [:status_id, 'o'] if options[:open_only]

    content = link_to_filter tag.name, filters, :project_id => @project
    if options[:show_count]
      content << content_tag('span', "(#{tag.count})", :class => 'tag-count')
    end

    content_tag('span', content, :class => 'tag-label')
  end

  def render_project_tag_link(tag, options = {})
    content = link_to tag.name, :controller => :projects, :action => :index, :tag_search => tag.name

    if options[:show_count]
      content << content_tag('span', "(#{tag.count})", :class => 'tag-count')
    end
    content_tag('span', content, :class => 'tag-label')
  end


  # Renders list of tags
  # Clouds are rendered as block <tt>div</tt> with internal <tt>span</t> per tag.
  # Lists are rendered as unordered lists <tt>ul</tt>. Lists are ordered by
  # <tt>tag.count</tt> descending.
  # === Parameters
  # * <i>tags</i> = Array of Tag instances
  # * <i>options</i> = (optional) Options (override system settings)
  #   * show_count  - Boolean. Whenever show tag counts
  #   * open_only   - Boolean. Whenever link to the filter with "open" issues
  #                   only limit.
  #   * style       - list, cloud
  def render_tags_list(tags, options = {})
    unless tags.nil? or tags.empty?
      content, style = '', options.delete(:style)

      # prevent ActsAsTaggableOn::TagsHelper from calling `all`
      # otherwise we will need sort tags after `tag_cloud`
      tags = tags.all if tags.respond_to?(:all)

      case sorting = "#{RedmineTags.settings[:issues_sort_by]}:#{RedmineTags.settings[:issues_sort_order]}"
        when "name:asc";    tags.sort! { |a,b| a.name <=> b.name }
        when "name:desc";   tags.sort! { |a,b| b.name <=> a.name }
        when "count:asc";   tags.sort! { |a,b| a.count <=> b.count }
        when "count:desc";  tags.sort! { |a,b| b.count <=> a.count }
        # Unknown sorting option. Fallback to default one
        else
          logger.warn "[redmine_tags] Unknown sorting option: <#{sorting}>"
          tags.sort! { |a,b| a.name <=> b.name }
      end

      if :list == style
        list_el, item_el = 'ul', 'li'
      elsif :cloud == style
        list_el, item_el = 'div', 'span'
        tags = cloudify(tags)
      else
        raise "Unknown list style"
      end

      content = content.html_safe
      tag_cloud tags, (1..8).to_a do |tag, weight|
        content << " ".html_safe + content_tag(item_el, render_project_tag_link(tag, options), :class => "tag-nube-#{weight}") + " ".html_safe
      end

      content_tag(list_el, content, :class => 'tags')
    end
  end

  private

  # make snowball. first tags comes in th middle.
  def cloudify(tags)
    temp, tags, trigger = tags, [], true
    temp.each do |tag|
      tags.send((trigger ? 'push' : 'unshift'), tag)
      trigger = !trigger
    end
    tags
  end

end
