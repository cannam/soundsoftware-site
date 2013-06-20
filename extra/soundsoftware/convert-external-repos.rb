#!/usr/bin/env ruby

# == Synopsis
#
# convert-external-repos: Update local Mercurial mirrors of external repos,
# by running an external command for each project requiring an update.
#
# == Usage
#
#    convert-external-repos [OPTIONS...] -s [DIR] -r [HOST]
#     
# == Arguments (mandatory)
#
#   -s, --scm-dir=DIR         use DIR as base directory for repositories
#   -r, --redmine-host=HOST   assume Redmine is hosted on HOST. Examples:
#                             -r redmine.example.net
#                             -r http://redmine.example.net
#                             -r https://example.net/redmine
#   -k, --key=KEY             use KEY as the Redmine API key
#   -c, --command=COMMAND     use this command to update each external
#                             repository: command is called with the name
#                             of the project, the path to its repo, and
#                             its external repo url as its three args
#
# == Options
#
#   --http-user=USER          User for HTTP Basic authentication with Redmine WS
#   --http-pass=PASSWORD      Password for Basic authentication with Redmine WS
#   -t, --test                only show what should be done
#   -h, --help                show help and exit
#   -v, --verbose             verbose
#   -V, --version             print version and exit
#   -q, --quiet               no log


require 'getoptlong'
require 'find'
require 'etc'

Version = "1.0"

opts = GetoptLong.new(
                      ['--scm-dir',      '-s', GetoptLong::REQUIRED_ARGUMENT],
                      ['--redmine-host', '-r', GetoptLong::REQUIRED_ARGUMENT],
                      ['--key',          '-k', GetoptLong::REQUIRED_ARGUMENT],
                      ['--http-user',          GetoptLong::REQUIRED_ARGUMENT],
                      ['--http-pass',          GetoptLong::REQUIRED_ARGUMENT],
                      ['--command' ,     '-c', GetoptLong::REQUIRED_ARGUMENT],
                      ['--test',         '-t', GetoptLong::NO_ARGUMENT],
                      ['--verbose',      '-v', GetoptLong::NO_ARGUMENT],
                      ['--version',      '-V', GetoptLong::NO_ARGUMENT],
                      ['--help'   ,      '-h', GetoptLong::NO_ARGUMENT],
                      ['--quiet'  ,      '-q', GetoptLong::NO_ARGUMENT]
                      )

$verbose      = 0
$quiet        = false
$redmine_host = ''
$repos_base   = ''
$http_user    = ''
$http_pass    = ''
$test         = false

$mirrordir    = '/var/mirror'

def log(text, options={})
  level = options[:level] || 0
  puts text unless $quiet or level > $verbose
  exit 1 if options[:exit]
end

def system_or_raise(command)
  raise "\"#{command}\" failed" unless system command
end

begin
  opts.each do |opt, arg|
    case opt
    when '--scm-dir';        $repos_base   = arg.dup
    when '--redmine-host';   $redmine_host = arg.dup
    when '--key';            $api_key      = arg.dup
    when '--http-user';      $http_user    = arg.dup
    when '--http-pass';      $http_pass    = arg.dup
    when '--command';        $command      = arg.dup
    when '--verbose';        $verbose += 1
    when '--test';           $test = true
    when '--version';        puts Version; exit
    when '--help';           puts "Read source for documentation"; exit 
    when '--quiet';          $quiet = true
    end
  end
rescue
  exit 1
end

if $test
  log("running in test mode")
end

if ($redmine_host.empty? or $repos_base.empty? or $command.empty?)
  puts "Read source for documentation"; exit
end

unless File.directory?($repos_base)
  log("directory '#{$repos_base}' doesn't exist", :exit => true)
end

begin
  require 'active_resource'
rescue LoadError
  log("This script requires activeresource.\nRun 'gem install activeresource' to install it.", :exit => true)
end

class Project < ActiveResource::Base
  self.headers["User-agent"] = "SoundSoftware external repository converter/#{Version}"
  self.format = :xml
end

log("querying Redmine for projects...", :level => 1);

$redmine_host.gsub!(/^/, "http://") unless $redmine_host.match("^https?://")
$redmine_host.gsub!(/\/$/, '')

Project.site = "#{$redmine_host}/sys";
Project.user = $http_user;
Project.password = $http_pass;

begin
  # Get all active projects that have the Repository module enabled
  projects = Project.find(:all, :params => {:key => $api_key})
rescue ActiveResource::ForbiddenAccess
  log("Request was denied by your Redmine server. Make sure that 'WS for repository management' is enabled in application settings and that you provided the correct API key.")
rescue => e
  log("Unable to connect to #{Project.site}: #{e}", :exit => true)
end

if projects.nil?
  log('no project found, perhaps you forgot to "Enable WS for repository management"', :exit => true)
end

log("retrieved #{projects.size} projects", :level => 1)

projects.each do |project|
  log("treating project #{project.name}", :level => 1)

  if project.identifier.empty?
    log("\tno identifier for project #{project.name}")
    next
  elsif not project.identifier.match(/^[a-z0-9\-]+$/)
    log("\tinvalid identifier for project #{project.name} : #{project.identifier}");
    next
  end

  if !project.respond_to?(:repository) or !project.repository.is_external?
    log("\tproject #{project.identifier} does not use an external repository");
    next
  end

  external_url = project.repository.external_url;
  log("\tproject #{project.identifier} has external repository url #{external_url}");

  if !external_url.match(/^[a-z][a-z+]{0,8}[a-z]:\/\//)
    log("\tthis doesn't look like a plausible url to me, skipping")
    next
  end

  repos_path = File.join($repos_base, project.identifier).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)

  unless File.directory?(repos_path)
    log("\tproject repo directory '#{repos_path}' doesn't exist")
    next
  end

  system($command, project.identifier, repos_path, external_url)
  
  $cache_clearance_file = File.join($mirrordir, project.identifier, 'url_changed')
  if File.file?($cache_clearance_file)
    log("\tproject repo url has changed, requesting cache clearance")
    if project.post(:repository_cache, :key => $api_key)
      File.delete($cache_clearance_file)
    end
  end

end
  
