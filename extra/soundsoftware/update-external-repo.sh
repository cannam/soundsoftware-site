#!/bin/sh

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


  
  
