# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2013  Jean-Philippe Lang
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

module ActivitiesHelper

  def date_of_event(e)
    if e.respond_to? :updated_at
      e.updated_at
    elsif e.respond_to? :updated_on
      e.updated_on
    elsif e.respond_to? :created_on
      e.created_on
    elsif e.respond_to? :committed_on
      e.committed_on
    else
      nil 
    end
  end

  def project_activity_on_events(events)

    # Score each project for which there are any events, by giving
    # each event a score based on how long ago it was (the more recent
    # the better). Return a hash mapping project id to score.

    projhash = Hash.new
    
    events.each do |e|
      if e.respond_to?(:project)
        p = e.project
        d = date_of_event e
        if !d.nil?
          dd = Date.parse d.to_s
          age = Date.today - dd
          score = (age < 14 ? 15-age : 1)
          if projhash.key? p
            projhash[p] += score
          else
            projhash[p] = score
          end
        end
      end
    end

    projhash
  end

  def projects_by_activity(user, count)

    # Return up to count of the user's project ids ordered by that user's
    # recent activity, omitting any projects for which no activity
    # occurred in the recent past and any projects not visible to
    # the current user

    activity = Redmine::Activity::Fetcher.new(User.current, :author => user)

    # Limit scope so as to exclude issues (which non-members can add)
    activity.scope = [ "changesets", "files", "documents", "news", "wiki_edits", "messages", "time_entries", "publications" ]

    days = Setting.activity_days_default.to_i
    events = activity.events(Date.today - days, Date.today + 1)
    projhash = project_activity_on_events(events)
    projhash.keys.sort_by { |k| -projhash[k] }.first(count)
  end

  def render_active_colleagues(colleagues)

    s = ""

    start = Time.now

    my_inst = ""
    if ! User.current.ssamr_user_detail.nil?
      my_inst = User.current.ssamr_user_detail.institution_name
    end

    actives = Hash.new
    for c in colleagues
      u = User.find_by_id(c)
      active_projects = projects_by_activity(u, 3)
      if !active_projects.empty?
        actives[c] = active_projects
      end
    end

    if actives.empty?
      l(:label_no_active_colleagues)
    else

      s << "<dl>"
      for c in actives.keys.sample(10)
        u = User.find_by_id(c)
        s << "<dt>"
        s << avatar(u, :size => '24')
        s << "<span class='user'>"
        s << h(u.name)
        s << "</span>"
        if !u.ssamr_user_detail.nil?
          inst = u.ssamr_user_detail.institution_name
          if inst != "" and inst != my_inst
            s << " - <span class='institution'>"
            s << h(u.ssamr_user_detail.institution_name)
            s << "</span>"
          end
        end
        s << "</dt>"
        s << "<dd>"
        s << "<span class='active'>"
        s << (actives[c].map { |p| link_to_project(p) }.join ", ")
        s << "</span>"
      end
      s << "</dl>"

      finish = Time.now
      logger.info "render_active_colleagues: took #{finish-start}"
    
      s
    end
  end

  def busy_projects(events, count)

    # Return a list of count projects randomly selected from amongst
    # the busiest projects represented by the given activity events

    projhash = project_activity_on_events(events)

    # pick N highest values and use cutoff value as selection threshold
    threshold = projhash.values.sort.last(count).first

    # select projects above threshold and pick N from them randomly
    busy = projhash.keys.select { |k| projhash[k] >= threshold }.sample(count)

    # return projects rather than just ids
    busy.map { |pid| Project.find(pid) }
  end

  def busy_institutions(events, count)
    authors = events.map do |e|
      e.event_author unless !e.respond_to?(:event_author) 
    end.compact
    institutions = authors.map do |a|
      if a.respond_to?(:ssamr_user_detail) and !a.ssamr_user_detail.nil?
        a.ssamr_user_detail.institution_name
      end
    end
    insthash = institutions.compact.sort.group_by { |i| i }
    insthash = insthash.merge(insthash) { |k,v| v.length }
    threshold = insthash.values.sort.last(count).first
    insthash.keys.select { |k| insthash[k] >= threshold }.sample(count)
  end
  
  def sort_activity_events(events)
    events_by_group = events.group_by(&:event_group)
    sorted_events = []
    events.sort {|x, y| y.event_datetime <=> x.event_datetime}.each do |event|
      if group_events = events_by_group.delete(event.event_group)
        group_events.sort {|x, y| y.event_datetime <=> x.event_datetime}.each_with_index do |e, i|
          sorted_events << [e, i > 0]
        end
      end
    end
    sorted_events
  end

end
