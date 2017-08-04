#!/bin/bash

#!!! still not covered:
# * user-supplied db password
# * cron jobs
# * https
# * web fonts

set -e

for f in /vagrant/provision.d/[0-9]* ; do
    case "$f" in
        *~) ;;
        *) echo "Running provision script: $f"
           /bin/bash "$f";;
    esac
done

