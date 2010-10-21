#!/usr/bin/env ruby

# == Synopsis
#
# reposman: manages your repositories with Redmine
#
# == Usage
#
#    reposman [OPTIONS...] -s [DIR] -r [HOST]
#     
#  Examples:
#    reposman --svn-dir=/var/svn --redmine-host=redmine.example.net --scm subversion
#    reposman -s /var/git -r redmine.example.net -u http://svn.example.net --scm git
#
# == Arguments (mandatory)
#
#   -s, --svn-dir=DIR         use DIR as base directory for svn repositories
#   -r, --redmine-host=HOST   assume Redmine is hosted on HOST. Examples:
#                             -r redmine.example.net
#                             -r http://redmine.example.net
#                             -r https://example.net/redmine
#   -k, --key=KEY             use KEY as the Redmine API key
#
# == Options
#
#   -o, --owner=OWNER         owner of the repository. using the rails login
#                             allow user to browse the repository within
#                             Redmine even for private project. If you want to
#                             share repositories through Redmine.pm, you need
#                             to use the apache owner.
#   -g, --group=GROUP         group of the repository. (default: root)
#   --scm=SCM                 the kind of SCM repository you want to create (and
#                             register) in Redmine (default: Subversion).
#                             reposman is able to create Git and Subversion
#                             repositories. For all other kind, you must specify
#                             a --command option
#   -u, --url=URL             the base url Redmine will use to access your
#                             repositories. This option is used to automatically
#                             register the repositories in Redmine. The project
#                             identifier will be appended to this url. Examples:
#                             -u https://example.net/svn
#                             -u file:///var/svn/
#                             if this option isn't set, reposman will register
#                             the repositories with local file paths in Redmine
#   -c, --command=COMMAND     use this command instead of "svnadmin create" to
#                             create a repository. This option can be used to
#                             create repositories other than subversion and git
#                             kind.
#                             This command override the default creation for git
#                             and subversion.
#   --http-user=USER          User for HTTP Basic authentication with Redmine WS
#   --http-pass=PASSWORD      Password for Basic authentication with Redmine WS
#   -t, --test                only show what should be done
#   -h, --help                show help and exit
#   -v, --verbose             verbose
#   -V, --version             print version and exit
#   -q, --quiet               no log
#
# == References
# 
# You can find more information on the redmine's wiki : http://www.redmine.org/wiki/redmine/HowTos


require 'getoptlong'
require 'rdoc/usage'
require 'find'
require 'etc'

Version = "1.3"
SUPPORTED_SCM = %w( Subversion Darcs Mercurial Bazaar Git Filesystem )

opts = GetoptLong.new(
                      ['--svn-dir',      '-s', GetoptLong::REQUIRED_ARGUMENT],
                      ['--redmine-host', '-r', GetoptLong::REQUIRED_ARGUMENT],
                      ['--key',          '-k', GetoptLong::REQUIRED_ARGUMENT],
                      ['--owner',        '-o', GetoptLong::REQUIRED_ARGUMENT],
                      ['--group',        '-g', GetoptLong::REQUIRED_ARGUMENT],
                      ['--url',          '-u', GetoptLong::REQUIRED_ARGUMENT],
                      ['--command' ,     '-c', GetoptLong::REQUIRED_ARGUMENT],
                      ['--scm',                GetoptLong::REQUIRED_ARGUMENT],
                      ['--http-user',          GetoptLong::REQUIRED_ARGUMENT],
                      ['--http-pass',          GetoptLong::REQUIRED_ARGUMENT],
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
$svn_owner    = 'root'
$svn_group    = 'root'
$use_groupid  = true
$svn_url      = false
$test         = false
$scm          = 'Subversion'

def log(text, options={})
  level = options[:level] || 0
  puts text unless $quiet or level > $verbose
  exit 1 if options[:exit]
end

def system_or_raise(command)
  raise "\"#{command}\" failed" unless system command
end

module SCM

  module Subversion
    def self.create(path)
      system_or_raise "svnadmin create #{path}"
    end
  end

  module Git
    def self.create(path)
      Dir.mkdir path
      Dir.chdir(path) do
        system_or_raise "git --bare init --shared"
        system_or_raise "git update-server-info"
      end
    end
  end

end

begin
  opts.each do |opt, arg|
    case opt
    when '--svn-dir';        $repos_base   = arg.dup
    when '--redmine-host';   $redmine_host = arg.dup
    when '--key';            $api_key      = arg.dup
    when '--owner';          $svn_owner    = arg.dup; $use_groupid = false;
    when '--group';          $svn_group    = arg.dup; $use_groupid = false;
    when '--url';            $svn_url      = arg.dup
    when '--scm';            $scm          = arg.dup.capitalize; log("Invalid SCM: #{$scm}", :exit => true) unless SUPPORTED_SCM.include?($scm)
    when '--http-user';      $http_user    = arg.dup
    when '--http-pass';      $http_pass    = arg.dup
    when '--command';        $command =      arg.dup
    when '--verbose';        $verbose += 1
    when '--test';           $test = true
    when '--version';        puts Version; exit
    when '--help';           RDoc::usage
    when '--quiet';          $quiet = true
    end
  end
rescue
  exit 1
end

if $test
  log("running in test mode")
end

# Make sure command is overridden if SCM vendor is not handled internally (for the moment Subversion and Git)
if $command.nil?
  begin
    scm_module = SCM.const_get($scm)
  rescue
    log("Please use --command option to specify how to create a #{$scm} repository.", :exit => true)
  end
end

$svn_url += "/" if $svn_url and not $svn_url.match(/\/$/)

if ($redmine_host.empty? or $repos_base.empty?)
  RDoc::usage
end

unless File.directory?($repos_base)
  log("directory '#{$repos_base}' doesn't exists", :exit => true)
end

begin
  require 'active_resource'
rescue LoadError
  log("This script requires activeresource.\nRun 'gem install activeresource' to install it.", :exit => true)
end

class Project < ActiveResource::Base; end

log("querying Redmine for projects...", :level => 1);

$redmine_host.gsub!(/^/, "http://") unless $redmine_host.match("^https?://")
$redmine_host.gsub!(/\/$/, '')

Project.site = "#{$redmine_host}/sys";
Project.user = $http_user;
Project.password = $http_pass;

begin
  # Get all active projects that have the Repository module enabled
  projects = Project.find(:all, :params => {:key => $api_key})
rescue => e
  log("Unable to connect to #{Project.site}: #{e}", :exit => true)
end

if projects.nil?
  log('no project found, perhaps you forgot to "Enable WS for repository management"', :exit => true)
end

log("retrieved #{projects.size} projects", :level => 1)

def set_owner_and_rights(project, repos_path, &block)
  if RUBY_PLATFORM =~ /mswin/
    yield if block_given?
  else
    uid, gid = Etc.getpwnam($svn_owner).uid, ($use_groupid ? Etc.getgrnam(project.identifier).gid : Etc.getgrnam($svn_group).gid)
    right = project.is_public ? 02775 : 02770
    yield if block_given?
    Find.find(repos_path) do |f|
      File.chmod right, f
      File.chown uid, gid, f
    end
  end
end

def other_read_right?(file)
  (File.stat(file).mode & 0007).zero? ? false : true
end

def owner_name(file)
  mswin? ?
    $svn_owner :
    Etc.getpwuid( File.stat(file).uid ).name  
end
  
def mswin?
  (RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
end

projects.each do |project|
  log("treating project #{project.name}", :level => 1)

  if project.identifier.empty?
    log("\tno identifier for project #{project.name}")
    next
  elsif not project.identifier.match(/^[a-z0-9\-]+$/)
    log("\tinvalid identifier for project #{project.name} : #{project.identifier}");
    next;
  end

  repos_path = File.join($repos_base, project.identifier).gsub(File::SEPARATOR, File::ALT_SEPARATOR || File::SEPARATOR)

  create_repos = false

  # Logic required for SoundSoftware.ac.uk repositories:
  #
  # * If the project has a repository path declared already,
  #   - if it's a local path,
  #     - if it does not exist
  #       - if it has the right root
  #         - create it
  #   - else
  #     - leave alone (remote repository)
  # * else
  #   - create repository with same name as project
  #   - set to project

  if project.respond_to?(:repository)

    repos_url = project.repository.url;
    log("\texisting url for project #{project.identifier} is #{repos_url}");

    if repos_url.match(/^file:\//) || repos_url.match(/^\//)

      repos_url = repos_url.gsub(/^file:\/*/, "/");
      log("\tthis is a local file path, at #{repos_url}");

      if repos_url.slice(0, $repos_base.length) != $repos_base
        log("\tit is in the wrong place: replacing it");
        # leave repos_path set to our original suggestion
        create_repos = true
      else
        if !File.directory?(repos_url)
          log("\tit doesn't exist; we should create it");
          repos_path = repos_url
          create_repos = true
        else
          log("\tit exists and is in the right place");
        end
      end
    else
      log("\tthis is a remote path, leaving alone");
    end
  else
    log("\tproject #{project.identifier} has no repository registered")
#    if File.directory?(repos_path)
#      log("\trepository path #{repos_path} already exists, not creating")
#    else 
      create_repos = true
#    end
  end

  if create_repos

    registration_url = repos_path
    if $svn_url
      registration_url = "#{$svn_url}#{project.identifier}"
    end

    if $test
      log("\tproposal: create repository #{repos_path}")
      log("\tproposal: register repository #{repos_path} in Redmine with vendor #{$scm}, url #{registration_url}")
      next
    end

    project.is_public ? File.umask(0002) : File.umask(0007)
    log("\taction: create repository #{repos_path}")

    begin
      if !File.directory?(repos_path)
        set_owner_and_rights(project, repos_path) do
          if scm_module.nil?
            log("\trunning command: #{$command} #{repos_path}")
            system_or_raise "#{$command} #{repos_path}"
          else
            scm_module.create(repos_path)
          end
        end
      end
    rescue => e
      log("\tunable to create #{repos_path} : #{e}\n")
      next
    end

    begin
      log("\taction: register repository #{repos_path} in Redmine with vendor #{$scm}, url #{registration_url}");
      project.post(:repository, :vendor => $scm, :repository => {:url => "#{registration_url}"}, :key => $api_key)
    rescue => e
      log("\trepository #{repos_path} not registered in Redmine: #{e.message}");
    end

    log("\trepository #{repos_path} created");
  end

end
  
