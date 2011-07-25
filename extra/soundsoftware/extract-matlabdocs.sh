#!/bin/bash

docdir="/var/doc"

progdir=$(dirname $0)
case "$progdir" in
    /*) ;;
    *) progdir="$(pwd)/$progdir" ;;
esac

project="$1"
projectdir="$2"
targetdir="$3"

if [ -z "$project" ] || [ -z "$targetdir" ] || [ -z "$projectdir" ]; then
    echo "Usage: $0 <project> <projectdir> <targetdir>"
    exit 2
fi

if [ ! -d "$projectdir" ]; then
    echo "Project directory $projectdir not found"
    exit 1
fi

if [ ! -d "$targetdir" ]; then
    echo "Target dir $targetdir not found"
    exit 1
fi

if [ -f "$targetdir/index.html" ]; then
    echo "Target dir $targetdir already contains index.html"
    exit 1
fi

mfile=$(find "$projectdir" -type f -name \*.m -print0 | xargs -0 grep -l '^% ' | head -1)

if [ -z "$mfile" ]; then
    echo "No MATLAB files with comments found for project $project"
    exit 1
fi

echo "Project $project contains at least one MATLAB file with comments"

cd "$projectdir" || exit 1

perl "$progdir/matlab-docs.pl" -c "$progdir/matlab-docs.conf" -d "$targetdir"

