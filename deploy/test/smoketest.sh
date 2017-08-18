#!/bin/bash

# The big problem with this test script is that it needs the cron
# scripts that generate some of this stuff to have been run at least
# once

usage() {
    echo 1>&2
    echo "Usage: $0 <uri-base>" 1>&2
    echo 1>&2
    echo "  e.g. $0 https://code.soundsoftware.ac.uk" 1>&2
    echo "    or $0 http://localhost:8080" 1>&2
    echo 1>&2
    exit 2
}

uribase="$1"
if [ -z "$uribase" ]; then
    usage
fi

set -eu

# A project known to exist, be public, and have a repository
project_with_repo=vamp-plugin-sdk

# A project known to exist, be public, and have embedded documentation
project_with_docs=vamp-plugin-sdk

# A project known to exist, be public, and have a bibliography
project_with_biblio=sonic-visualiser

tried=0
succeeded=0

mydir=$(dirname "$0")

try() {
    mkdir -p "$mydir/output"
    origin=$(pwd)
    cd "$mydir/output"
    path="$1"
    description="$2"
    url="$uribase$path"
    echo
    echo "Trying \"$description\" [$url]..."
    echo
    if wget "$url" ; then
        echo "+++ Succeeded"
        succeeded=$(($succeeded + 1))
    else
        echo "--- FAILED"
    fi
    tried=$(($tried + 1))
    cd "$origin"
}

try "/" "Front page"
try "/projects/$project_with_repo" "Project page"
try "/projects/$project_with_biblio" "Project page with bibliography"
try "/projects/$project_with_repo/repository" "Repository page"
try "/hg/$project_with_repo" "Mercurial repo"
try "/projects/$project_with_docs/embedded" "Project documentation page (from docgen cron script)"
try "/git/$project_with_repo/info/refs" "Git repo mirror"

echo
echo "Passed $succeeded of $tried"
echo

