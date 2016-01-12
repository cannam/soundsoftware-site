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

authordir="$gitdir/AUTHORMAPS"

mkdir -p "$authordir"

echo "About to extract author maps..."

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
	echo "Authormap file $authormap not found for repo $hgrepo, skipping: the create-repo-authormaps script already run by this script should have created an authormap file (even if empty) for every repo with a corresponding project"
	continue
    fi
    
    if [ ! -d "$gitrepo" ]; then
	git init "$gitrepo"
    fi

    echo "About to run fast export for repo $reponame..."
    
    (
	cd "$gitrepo"
	"$fastexport" -r "$hgrepo" -A "$authormap"
    )

    echo "Fast export done"
    
done

echo "All done"

