#!/bin/bash

#!!! still not covered:
# * cron jobs
# * https
# * web fonts
# * reposman scripts (and their API key setup, etc)
# * docgen script install
# * logrotate config (check against system one)

set -e

for f in /code-to-deploy/deploy/provision.d/[0-9]* ; do
    case "$f" in
        *~) ;;
        *) echo "Running provision script: $f"
           /bin/bash "$f";;
    esac
done

