#!/usr/bin/env ruby

# Create authormap files for hg repos based on the changeset & project
# member info available to Redmine.
#
# We have a set of hg repos in a given directory:
#
# /var/hg/repo_1
# /var/hg/repo_2
# /var/hg/repo_3
#
# and we want to produce authormap files in another directory:
#
# /var/repo-export/authormap/authormap_repo_1
# /var/repo-export/authormap/authormap_repo_2
# /var/repo-export/authormap/authormap_repo_3
#
# This script does that, if given the two directory names as arguments
# to the -s and -o options. In the above example:
#
# create-repo-authormaps.rb -s /var/hg -o /var/repo-export/authormap
#
# Note that this script will overwrite any existing authormap
# files. (That's why the output files are given an authormap_ prefix,
# so we're less likely to clobber something else if the user gets the
# arguments wrong.)

require 'getoptlong'

opts = GetoptLong.new(
                      ['--scm-dir',      '-s', GetoptLong::REQUIRED_ARGUMENT],
                      ['--out-dir',      '-o', GetoptLong::REQUIRED_ARGUMENT]
)

$repos_base   = ''
$out_base     = ''

def usage
  puts "See source code for supported options"
  exit
end

begin
  opts.each do |opt, arg|
    case opt
    when '--scm-dir';   $repos_base   = arg.dup
    when '--out-dir';   $out_base     = arg.dup
    end
  end
rescue
  exit 1
end

if ($repos_base.empty? or $out_base.empty?)
  usage
end

unless File.directory?($repos_base)
  log("input directory '#{$repos_base}' doesn't exist", :exit => true)
end

unless File.directory?($out_base)
  log("output directory '#{$out_base}' doesn't exist", :exit => true)
end

projects = Project.find(:all)

if projects.nil?
  log('No projects found', :exit => true)
end

projects.each do |proj|
  next unless proj.respond_to?(:repository)

  repo = proj.repository

  repo_url = repo.url
  repo_url = repo_url.gsub(/^file:\/*/, "/");
  if repo_url != File.join($repos_base, proj.identifier)
    log('Project #{proj.identifier} has repo in unsupported location #{repo_url}, skipping')
    next
  end

  csets = repo.changesets
  committers = csets.map do |c| c.committer end.sort.uniq

  authormap = ""
  committers.each do |c|
    if not c =~ /[^<]+<.*@.*>/ then
      user = repo.find_committer_user c
      authormap << "#{c}=#{u.name} <#{u.mail}>\n" unless u.nil?
    end
  end

  File.open (File.join($out_base, "authormap_#{proj.identifier}"), "w") do |f|
    f.puts(authormap)
  end

end

