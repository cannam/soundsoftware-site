#!/bin/bash
#
# Convert an Hg repo with subrepos into a new repo in which the
# subrepo contents are included in the main repo. The history of the
# original and its subrepos is retained.
#
# Note that this script invokes itself, in order to handle nested
# subrepos.
#
# While this does work, I'm not convinced it's entirely a good
# idea. The history ends up a bit of a mess, and if it's a preliminary
# to converting to git (which is one obvious reason to do this), the
# history ends up even messier after that conversion.

set -ex

repo="$1"
target="$2"
target_subdir="$3"
revision="$4"

if [ -z "$repo" ] || [ -z "$target" ]; then
    echo "usage: $0 <repo-url> <target-dir> [<target-subdir> <revision>]"
    exit 2
fi

set -u

myname="$0"
mydir=$(dirname "$myname")

reponame=$(basename "$repo")
tmpdir="/tmp/flatten_$$"
mkdir -p "$tmpdir"
trap "rm -rf ${tmpdir}" 0

filemap="$tmpdir/filemap"
tmprepo="$tmpdir/tmprepo"
subtmp="$tmpdir/subtmp"

if [ -n "$revision" ]; then
    hg clone -r "$revision" "$repo" "$tmprepo"
else
    hg clone "$repo" "$tmprepo"
fi

read_sub() {
    if [ -f "$tmprepo/.hgsub" ]; then
	cat "$tmprepo/.hgsub" | sed 's/ *= */,/'
    fi
}

(   echo "exclude .hgsub"
    echo "exclude .hgsubstate"
    read_sub | while IFS=, read dir uri; do
	echo "exclude $dir"
    done
    if [ -n "$target_subdir" ]; then
	echo "rename . $target_subdir"
    fi
) > "$filemap"

hg convert --filemap "$filemap" "$tmprepo" "$target"
(   cd "$target"
    hg update
)

read_sub | while IFS=, read dir uri; do
    rm -rf "$subtmp"
    revision=$(grep ' '"$dir"'$' "$tmprepo/.hgsubstate" | awk '{ print $1; }')
    if [ -n "$target_subdir" ]; then
	"$myname" "$tmprepo/$dir" "$subtmp" "$target_subdir/$dir" "$revision"
    else
	"$myname" "$tmprepo/$dir" "$subtmp" "$dir" "$revision"
    fi
    (   cd "$target"
	hg pull -f "$subtmp" &&
	    hg merge --tool internal:local &&
	    hg commit -m "Merge former subrepo $dir"
    )
done

