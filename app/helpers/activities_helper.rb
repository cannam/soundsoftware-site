
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

  def busy_projects(events, count)

    # Score each project for which there are any events, by giving
    # each event a score based on how long ago it was (the more recent
    # the better).

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
