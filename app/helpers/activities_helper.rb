
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

    # Return up to count of the user's projects ordered by that user's
    # recent activity, omitting any projects for which no activity
    # occurred in the recent past

    activity = Redmine::Activity::Fetcher.new(user, :author => user)
    days = Setting.activity_days_default.to_i
    events = activity.events(Date.today - days, Date.today + 1)
    projhash = project_activity_on_events(events)
    projhash.keys.sort_by { |k| -projhash[k] }.first(count)
  end

  def render_active_colleagues(colleagues)

    s = ""

    for c in colleagues
      u = User.find_by_id(c)
      active_projects = projects_by_activity(u, 3)
      if !active_projects.empty?
        s << "<div class='user'>"
        s << link_to_user(u)
        s << "<span class='institution'>"
        s << h(u.ssamr_user_detail.institution_name)
        s << "</span>"
        s << "</div>"
        s << "<div class='active'>"
        s << l(:label_working_in) << " "
        s << (active_projects.map { |p| link_to_project(p) }.join ", ")
        s << "</div>"
      end
    end
    
    if s != ""
      s
    else
      l(:label_no_active_colleagues)
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

end
