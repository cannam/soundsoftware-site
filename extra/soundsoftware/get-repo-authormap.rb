
# Print out an authormap file for hg-to-git conversion using
# hg-fast-export
#
# Invoke with the project identifier as argument, e.g.
#
# ./script/rails runner -e production extra/soundsoftware/get-repo-authormap.rb soundsoftware-site

proj_ident = ARGV.last
proj = Project.find_by_identifier(proj_ident)
repo = Repository.where(:project_id => proj.id).first
csets = Changeset.where(:repository_id => repo.id)
committers = csets.map do |c| c.committer end.sort.uniq
committers.each do |c|
  if not c =~ /[^<]+<.*@.*>/ then
    u = repo.find_committer_user c
    print "#{c}=#{u.name} <#{u.mail}>\n" unless u.nil?
  end
end
