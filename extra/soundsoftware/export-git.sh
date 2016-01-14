#!/bin/bash

set -e

progdir=$(dirname $0)
case "$progdir" in
    /*) ;;
    *) progdir="$(pwd)/$progdir" ;;
esac

rails_scriptdir="$progdir/../../script"
rails="$rails_scriptdir/rails"

if [ ! -x "$rails" ]; then
    echo "Expected to find rails executable at $rails"
    exit 2
fi

fastexport="$progdir/../fast-export/hg-fast-export.sh"
if [ ! -x "$fastexport" ]; then
    echo "Expected to find hg-fast-export.sh executable at $fastexport"
    exit 2
fi

environment="$1"
hgdir="$2"
gitdir="$3"

if [ -z "$hgdir" ] || [ -z "$gitdir" ]; then
    echo "Usage: $0 <environment> <hgdir> <gitdir>"
    echo "  where"
    echo "  - environment is the Rails environment (development or production)"
    echo "  - hgdir is the directory containing project Mercurial repositories"
    echo "  - gitdir is the directory in which output git repositories are to be"
    echo "    created or updated"
    exit 2
fi

if [ ! -d "$hgdir" ]; then
    echo "Mercurial repository directory $hgdir not found"
    exit 1
fi

if [ ! -d "$gitdir" ]; then
    echo "Target git repository dir $gitdir not found (please create at least the empty directory)"
    exit 1
fi

set -u

authordir="$gitdir/__AUTHORMAPS"
mkdir -p "$authordir"

wastedir="$gitdir/__WASTE"
mkdir -p "$wastedir"

echo
echo "$0 starting at $(date)"

echo "Extracting author maps..."

# Delete any existing authormap files, because we want to ensure we
# don't have an authormap for any project that was exportable but has
# become non-exportable (e.g. has gone private)
rm -f "$authordir/*"

"$rails" runner -e "$environment" "$progdir/create-repo-authormaps.rb" \
	 -s "$hgdir" -o "$authordir"

for hgrepo in "$hgdir"/*; do

    if [ ! -d "$hgrepo/.hg" ]; then
	echo "Directory $hgrepo does not appear to be a Mercurial repo, skipping"
	continue
    fi

    reponame=$(basename "$hgrepo")
    authormap="$authordir/authormap_$reponame"
    gitrepo="$gitdir/$reponame"

    if [ ! -f "$authormap" ]; then
	echo "No authormap file was created for repo $reponame, skipping"

	# If there is no authormap file, then we should not have a git
	# mirror -- this is a form of access control, not just an
	# optimisation (authormap files are expected to exist for all
	# exportable projects, even if empty). So if a git mirror
	# exists, we move it away
	if [ -d "$gitrepo" ]; then
	    mv "$gitrepo" "$wastedir/$(date +%s).$reponame"
	fi
	    
	continue
    fi
    
    if [ ! -d "$gitrepo" ]; then
	git init "$gitrepo"
    fi

    echo
    echo "About to run fast export for repo $reponame..."
    
    (
	cd "$gitrepo"

        # Force is necessary because git-fast-import (or git) can't handle
        # branches having more than one head ("Error: repository has at
        # least one unnamed head"), which happens from time to time in
        # valid Hg repos. With --force apparently it will just pick one
        # of the two heads arbitrarily, which is also alarming but is
        # more likely to be useful 
	"$fastexport" --quiet -r "$hgrepo" -A "$authormap" --force

        git update-server-info
    )

    echo "Fast export done"
    
done

echo "$0 finishing at $(date)"

