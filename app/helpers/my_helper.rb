# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module MyHelper

  def all_colleagues_of(user)
    # Return a list of all user ids who have worked with the given user
    # (on projects that are visible to the current user)
    user.projects.select { |p| p.visible? }.map { |p| p.members.map { |m| m.user_id } }.flatten.sort.uniq.reject { |i| user.id == i }
  end

  def render_active_colleagues(colleagues)

    s = ""

    start = Time.now

    my_inst = ""
    if ! User.current.ssamr_user_detail.nil?
      my_inst = User.current.ssamr_user_detail.institution_name
    end

    for c in colleagues
      u = User.find_by_id(c)
      active_projects = projects_by_activity(u, 3)
      if !active_projects.empty?
        s << "<div class='active-person'>"
        s << avatar(u, :size => '24')
        s << "<span class='user'>"
        s << h(u.name)
        s << "</span>"
        if !u.ssamr_user_detail.nil?
          inst = u.ssamr_user_detail.institution_name
          if inst != "" and inst != my_inst
            s << " - <span class='institution'>"
            s << h(inst)
            s << "</span>"
          end
        end
        s << "<br>"
        s << "<span class='active'>"
        s << (active_projects.map { |p| link_to_project(p) }.join ", ")
        s << "</span>"
        s << "</div>"
      end
    end

    finish = Time.now
    logger.info "render_active_colleagues: took #{finish-start}"
    
    if s != ""
      s
    else
      l(:label_no_active_colleagues)
    end
  end

end
