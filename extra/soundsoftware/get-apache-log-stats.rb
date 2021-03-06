
# Read an Apache log file in SoundSoftware site format from stdin and
# produce some per-project stats.
#
# Invoke with e.g.
#
# cat /var/log/apache2/code-access.log | \
#   script/runner -e production extra/soundsoftware/get-apache-log-stats.rb


# Use the ApacheLogRegex parser, a neat thing
# See http://www.simonecarletti.com/blog/2009/02/apache-log-regex-a-lightweight-ruby-apache-log-parser/
require 'apachelogregex'

# This is the format defined in our httpd.conf
vhost_combined_format = '%v:%p %h %{X-Forwarded-For}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"'

parser = ApacheLogRegex.new(vhost_combined_format)

# project name -> count of hg clones
clones = Hash.new(0)

# project name -> count of hg pulls
pulls = Hash.new(0)

# project name -> count of hg pushes
pushes = Hash.new(0)

# project name -> count of hg archive requests (i.e. Download as Zip)
zips = Hash.new(0)

# project name -> count of hits to pages under /projects/projectname
hits = Hash.new(0)

# project name -> Project object
@projects = Hash.new

parseable = 0
unparseable = 0

def is_public_project?(project)
  if !project
    false
  elsif project =~ /^\d+$/
    # ignore numerical project ids, they are only used when editing projects
    false
  elsif @projects.key?(project)
    @projects[project].is_public? 
  else
    pobj = Project.find_by_identifier(project)
    if pobj
      @projects[project] = pobj
      pobj.is_public?
    else
      print "Project not found: ", project, "\n"
      false
    end
  end
end

def print_stats(h)
  h.keys.sort { |a,b| h[b] <=> h[a] }.each do |p|
    if h[p] > 0
      print h[p], " ", @projects[p].name, " [", p, "]\n"
    end
  end
end

STDIN.each do |line|

  record = parser.parse(line)

  # most annoyingly, the parser can't handle the comma-separated list
  # in X-Forwarded-For where it has more than one element. If it has
  # failed, remove any IP addresses or the word "unknown" with
  # trailing commas and try again
  if not record
    filtered = line.gsub(/(unknown|([0-9]+\.){3}[0-9]+),\s*/, "")
    record = parser.parse(filtered)
  end

  # discard, but count, unparseable lines
  if not record
    print "Line not parseable: ", line, "\n"
    unparseable += 1
    next
  end

  # discard everything that isn't a 200 OK response
  next if record["%>s"] != "200"

  # discard anything apparently requested by a crawler
  next if record["%{User-Agent}i"] =~ /(bot|slurp|crawler|spider|Redmine)\b/i

  # pull out request e.g. GET / HTTP/1.0
  request = record["%r"]

  # split into method, path, protocol
  if not request =~ /^[^\s]+ ([^\s]+) [^\s]+$/
    print "Line not parseable (bad method, path, protocol): ", line, "\n"
    unparseable += 1
    next
  end

  # get the path e.g. /projects/weevilmatic and split on /
  path = $~[1]
  components = path.split("/")
  
  # should have at least two elements unless path is "/"; first should
  # be empty (begins with /)
  if path != "/" and (components.size < 2 or components[0] != "")
    print "Line not parseable (degenerate path): ", line, "\n"
    unparseable += 1
    next
  end

  if components[1] == "hg"
    
    # path is /hg/project?something or /hg/project/something

    project = components[2].split("?")[0]
    if not is_public_project?(project)
      next
    end

    if components[2] =~ /&roots=00*$/
      clones[project] += 1
    elsif components[2] =~ /cmd=capabilities/
      pulls[project] += 1
    elsif components[2] =~ /cmd=unbundle/
      pushes[project] += 1
    elsif components[3] == "archive"
      zips[project] += 1
    end

  elsif components[1] == "projects"

    # path is /projects/project or /projects/project/something

    project = components[2]
    project = project.split("?")[0] if project
    if not is_public_project?(project)
      next
    end

    hits[project] += 1

  end

  parseable += 1
end

# Each clone is also a pull; deduct it from the pulls hash, because we
# want that to contain only non-clone pulls

clones.keys.each do |project|
  pulls[project] -= 1
end

print parseable, " parseable\n"
print unparseable, " unparseable\n"


print "\nMercurial clones:\n"
print_stats clones

print "\nMercurial pulls (excluding clones):\n"
print_stats pulls

print "\nMercurial pushes:\n"
print_stats pushes

print "\nMercurial archive (zip file) downloads:\n"
print_stats zips

print "\nProject page hits (excluding crawlers):\n"
print_stats hits


