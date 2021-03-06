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
# ./script/rails runner -e production extra/soundsoftware/create-repo-authormaps.rb -s /var/hg -o /var/repo-export/authormap
#
# Note that this script will overwrite any existing authormap
# files. (That's why the output files are given an authormap_ prefix,
# so we're less likely to clobber something else if the user gets the
# arguments wrong.)

require 'getoptlong'

opts = GetoptLong.new(
                      ['--scm-dir', '-s', GetoptLong::REQUIRED_ARGUMENT],
                      ['--out-dir', '-o', GetoptLong::REQUIRED_ARGUMENT],
                      ['--environment', '-e', GetoptLong::OPTIONAL_ARGUMENT]
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
  puts "input directory '#{$repos_base}' doesn't exist"
  exit 1
end

unless File.directory?($out_base)
  puts "output directory '#{$out_base}' doesn't exist"
  exit 1
end

projects = Project.find(:all)

if projects.nil?
  puts 'No projects found'
  exit 1
end

projects.each do |proj|

  next unless proj.is_public

  next unless proj.respond_to?(:repository)

  repo = proj.repository
  next if repo.nil? or repo.url.empty?

  repo_url = repo.url
  repo_url = repo_url.gsub(/^file:\/*/, "/");
  if repo_url != File.join($repos_base, proj.identifier)
    puts "Project #{proj.identifier} has repo in unsupported location #{repo_url}, skipping"
    next
  end

  committers = repo.committers

  authormap = ""
  committers.each do |c, uid|

    # Some of our repos have broken email addresses in them: e.g. one
    # changeset has a committer name of the form
    #
    # NAME <name <NAME <name@example.com">
    #
    # I don't know how it got like that... If the committer has more
    # than one '<' in it, truncate it just before the first one, and
    # then look up the author name again.
    #
    if c =~ /<.*</ then
      # So this is a completely pathological case
      user = User.find_by_id uid
      if user.nil? then
        # because the given committer is bogus, we must write something in the map
        name = c.sub(/\s*<.*$/, "")
        authormap << "#{c}=#{name} <unknown@example.com>\n"
      else
        authormap << "#{c}=#{user.name} <#{user.mail}>\n"
      end
    elsif not c =~ /[^<]+<.*@.*>/ then
      # This is the "normal" case that needs work, where a user has
      # their name in the commit but no email address
      user = User.find_by_id uid
      authormap << "#{c}=#{user.name} <#{user.mail}>\n" unless user.nil?
    end
  end

  File.open(File.join($out_base, "authormap_#{proj.identifier}"), "w") do |f|
    f.puts(authormap)
  end

end

