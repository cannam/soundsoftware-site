
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

# project name -> count of hg commits
commits = Hash.new(0)

# project name -> count of hg archive requests (i.e. Download as Zip)
zips = Hash.new(0)

# project name -> count of hits to pages under /projects/projectname
hits = Hash.new(0)

parseable = 0
unparseable = 0

ARGF.each do |line|

  record = parser.parse(line)

  # most annoyingly, the parser can't handle the comma-separated list
  # in X-Forwarded-For where it has more than one element. If it has
  # failed, remove any IP addresses with trailing commas and try again
  if not record
    filtered = line.gsub(/([0-9]+\.){3}[0-9]+,\s*/, "")
    record = parser.parse(filtered)
  end

  # discard, but count, unparseable lines
  if not record
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
    unparseable += 1
    next
  end

  # get the path e.g. /projects/weevilmatic and split on /
  path = $~[1]
  components = path.split("/")
  
  # should have at least two elements unless path is "/"; first should
  # be empty (begins with /)
  if path != "/" and (components.size < 2 or components[0] != "")
    unparseable += 1
    next
  end

  if components[1] == "hg"
    
    # path is /hg/project?something or /hg/project/something

    project = components[2].split("?")[0]

    if components[2] =~ /&roots=00*$/
      clones[project] += 1
    elsif components[2] =~ /cmd=capabilities/
      pulls[project] += 1
    elsif components[3] == "archive"
      zips[project] += 1
    end

  elsif components[1] == "projects"

    # path is /projects/project or /projects/project/something

    project = components[2]
    if project
      project = project.split("?")[0]
      hits[project] += 1
    end

  end

  parseable += 1
end

# Each clone is also a pull; deduct it from the pulls hash, because we
# want that to contain only non-clone pulls

clones.keys.each do |project|
  pulls[project] -= 1
end

print clones, "\n"
print pulls, "\n"
print zips, "\n"
print hits, "\n"

print parseable, " parseable\n"
print unparseable, " unparseable\n"

