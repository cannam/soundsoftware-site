#!/bin/sh

mirrordir="/var/mirror"
hg="/usr/local/bin/hg"

project="$1"
local_repo="$2"
remote_repo="$3"

if [ -z "$project" ] || [ -z "$local_repo" ] || [ -z "$remote_repo" ]; then
    echo "Usage: $0 <project> <local-repo-path> <remote-repo-url>"
    exit 2
fi

  # We need to handle different source repository types separately.
  # 
  # The convert extension cannot convert directly from a remote git
  # repo; we'd have to mirror to a local repo first.  Incremental
  # conversions do work though.  The hg-git plugin will convert
  # directly from remote repositories, but not via all schemes
  # (e.g. https is not currently supported).  It's probably easier to
  # use git itself to clone locally and then convert or hg-git from
  # there.
  # 
  # We can of course convert directly from remote Subversion repos,
  # but we need to keep track of that -- you can ask to convert into a
  # repo that has already been used (for Mercurial) and it'll do so
  # happily; we don't want that.
  #
  # Converting from a remote Hg repo should be fine!
  #
  # One other thing -- we can't actually tell the difference between
  # the various SCM types based on URL alone.  We have to try them
  # (ideally in an order determined by a guess based on the URL) and
  # see what happens.

project_mirror="$mirrordir/$project"
mkdir -p "$project_mirror"
project_repo_mirror="$project_mirror/repo"

  # Some test URLs:
  # 
  # http://aimc.googlecode.com/svn/trunk/
  # http://aimc.googlecode.com/svn/
  # http://vagar.org/git/flam
  # https://github.com/wslihgt/IMMF0salience.git
  # http://hg.breakfastquay.com/dssi-vst/
  # git://github.com/schacon/hg-git.git
  # http://svn.drobilla.net/lad (externals!)

# If we are importing from another distributed system, then our aim is
# to create either a Hg repo or a git repo at $project_mirror, which
# we can then pull from directly to the Hg repo at $local_repo (using
# hg-git, in the case of a git repo).

# Importing from SVN, we should use hg convert directly to the target
# hg repo (or should we?) but keep a record of the last changeset ID
# we brought in, and test each time whether it matches the last
# changeset ID actually in the repo

success=""

# If we have a record of the last successfully updated remote repo
# URL, check it against our current remote URL: if it has changed, we
# will need to start again with a new clone rather than pulling
# updates into the existing local mirror

successfile="$project_mirror/last_successful_url"
if [ -f "$successfile" ]; then
    last=$(cat "$successfile")
    if [ x"$last" = x"$remote_repo" ]; then
	echo "$$: Remote URL is unchanged from last successful update"
    else
	echo "$$: Remote URL has changed since last successful update:"
	echo "$$: Last URL was $last, current is $remote_repo"
	suffix="$$.$(date +%s)"
	echo "$$: Moving existing repos to $suffix suffix and starting afresh"
	mv "$project_repo_mirror" "$project_repo_mirror"."$suffix"
	mv "$local_repo" "$local_repo"."$suffix"
	mv "$successfile" "$successfile"."$suffix"
	touch "$project_mirror/url_changed"
    fi
fi

if [ -d "$project_repo_mirror" ]; then

    # Repo mirror exists: update it
    echo "$$: Mirror for project $project exists at $project_repo_mirror, updating" 1>&2

    if [ -d "$project_repo_mirror/.hg" ]; then
	"$hg" --config extensions.convert= convert --datesort "$remote_repo" "$project_repo_mirror" && success=true
    elif [ -d "$project_repo_mirror/.git" ]; then
	( cd "$project_repo_mirror" && git pull "$remote_repo" master ) && success=true
    else 
	echo "$$: ERROR: Repo mirror dir $project_repo_mirror exists but is not an Hg or git repo" 1>&2
    fi

else

    # Repo mirror does not exist yet
    echo "$$: Mirror for project $project does not yet exist at $project_repo_mirror, trying to convert or clone" 1>&2

    case "$remote_repo" in
	*git*) 
	    git clone "$remote_repo" "$project_repo_mirror" ||
	    "$hg" --config extensions.convert= convert --datesort "$remote_repo" "$project_repo_mirror"
	    ;;
	*)
	    "$hg" --config extensions.convert= convert --datesort "$remote_repo" "$project_repo_mirror" ||
	    git clone "$remote_repo" "$project_repo_mirror" ||
	    "$hg" clone "$remote_repo" "$project_repo_mirror"
	    ;;
    esac && success=true

fi
	
echo "Success=$success"

if [ -n "$success" ]; then
    echo "$$: Update successful, pulling into local repo at $local_repo"
    if [ ! -d "$local_repo" ]; then
	"$hg" init "$local_repo"
    fi
    if [ -d "$project_repo_mirror/.git" ]; then
	( cd "$local_repo" && "$hg" --config extensions.hggit= pull "$project_repo_mirror" ) && echo "$remote_repo" > "$successfile"
    else 
	( cd "$local_repo" && "$hg" pull "$project_repo_mirror" ) && echo "$remote_repo" > "$successfile"
    fi
fi
