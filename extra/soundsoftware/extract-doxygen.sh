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

doxyfile=$(find "$projectdir" -type f -name Doxyfile -print | head -1)

if [ -z "$doxyfile" ]; then
    echo "No Doxyfile found for project $project"
    exit 1
fi

echo "Project $project contains a Doxyfile at $doxyfile"

cd "$projectdir" || exit 1

"$progdir/doxysafe.pl" "$doxyfile" | \
    sed -e '$a OUTPUT_DIRECTORY='"$targetdir" | \
    doxygen -

