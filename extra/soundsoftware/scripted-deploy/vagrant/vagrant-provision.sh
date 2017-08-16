#!/bin/bash

#!!! still not covered:
# * cron jobs
# * https
# * web fonts

set -e

for f in /vagrant-code/extra/soundsoftware/scripted-deploy/vagrant/provision.d/[0-9]* ; do
    case "$f" in
        *~) ;;
        *) echo "Running provision script: $f"
           /bin/bash "$f";;
    esac
done
