
module ActivitiesHelper

  def busy_projects(events, count)
    # Transform events list into hash from project id to number of
    # occurrences of project in list (there is surely a tidier way
    # to do this, e.g. chunk() in Ruby 1.9 but not in 1.8)
    phash = events.map { |e| e.project unless !e.respond_to?(:project) }.sort.group_by { |p| p.id }
    phash = phash.merge(phash) { |k,v| v.length }
    threshold = phash.values.sort.last(count).first
    busy = phash.keys.select { |k| phash[k] >= threshold }.sample(count)
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
