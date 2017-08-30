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

# A project known not to exist
nonexistent_project=nonexistent-project

# A file for download known to exist
file_for_download=/attachments/download/2210/vamp-plugin-sdk-2.7.1-binaries-osx.tar.gz

tried=0
succeeded=0

mydir=$(dirname "$0")

try() {
    mkdir -p "$mydir/output"
    origin=$(pwd)
    cd "$mydir/output"
    path="$1"
    description="$2"
    expected="$3"
    url="$uribase$path"
    echo
    echo "Trying \"$description\" [$url]..."
    echo
    if wget "$url" ; then
        echo "+++ Succeeded"
        succeeded=$(($succeeded + 1))
    else
        returned="$?"
        if [ "$returned" = "$expected" ]; then
            echo "+++ Succeeded [returned expected code $expected]"
            succeeded=$(($succeeded + 1))
        else
            echo "--- FAILED with return code $returned"
        fi
    fi
    tried=$(($tried + 1))
    cd "$origin"
}

assert() {
    try "$1" "$2" 0
}

fail() {
    try "$1" "$2" "$3"
}

assert "/" "Front page"
assert "/projects/$project_with_repo" "Project page"
assert "/projects/$project_with_biblio" "Project page with bibliography"
assert "/projects/$project_with_repo/repository" "Repository page"
assert "/hg/$project_with_repo" "Mercurial repo"
assert "/projects/$project_with_docs/embedded" "Project documentation page (from docgen cron script)"
assert "/git/$project_with_repo/info/refs" "Git repo mirror"
assert "$file_for_download" "File for download"

# we expect this to return an http auth requirement, not a 404 - the
# value 6 is wget's return code for auth failure
fail "/hg/$nonexistent_project" "Mercurial repo" 6

echo
echo "Passed $succeeded of $tried"
echo

