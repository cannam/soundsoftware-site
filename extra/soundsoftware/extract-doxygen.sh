#!/bin/bash

docdir="/var/doc"

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

# hmm. should be a whitelist

cat "$doxyfile" | \
    grep -vi OUTPUT_DIRECTORY | \
    grep -vi HTML_OUTPUT | \
    grep -vi SEARCHENGINE | \
    grep -vi HAVE_DOT | \
    grep -vi DOT_FONTNAME | \
    grep -vi DOT_FONTPATH | \
    grep -vi DOT_TRANSPARENT | \
    sed -e '$a OUTPUT_DIRECTORY='"$targetdir" \
    -e '$a HTML_OUTPUT = .' \
    -e '$a SEARCHENGINE = NO' \
    -e '$a HAVE_DOT = YES' \
    -e '$a DOT_FONTNAME = FreeMono' \
    -e '$a DOT_FONTPATH = /usr/share/fonts/truetype/freefont' \
    -e '$a DOT_TRANSPARENT = YES' | \
    doxygen -

