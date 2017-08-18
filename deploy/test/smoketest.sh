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

# A project that is known to exist, be public, and have embedded
# documentation
project=vamp-plugin-sdk

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
        tried=$(($tried + 1))
        succeeded=$(($succeeded + 1))
        cd "$origin"
        return 0
    else
        echo "--- FAILED"
        tried=$(($tried + 1))
        cd "$origin"
        return 1
    fi
}

try "/" "Front page"
try "/projects/$project" "Project page"
try "/projects/$project/repository" "Repository page"
try "/hg/$project" "Mercurial repo"
try "/projects/$project/embedded" "Project documentation page (from docgen cron script)"
try "/git/$project/info/refs" "Git repo mirror"

echo
echo "Passed $succeeded of $tried"
echo

