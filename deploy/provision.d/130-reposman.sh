#!/bin/bash

set -e

# Copy reposman (repository manager) scripts, including the generated
# scripts with interpolated API key etc, to the directory they will be
# run from.

# There are two sets of scripts here:
#
# 1. The reposman script that plods through all the projects that have
# repositories defined, creates those repositories on disc, and
# registers their locations with the projects. This happens often,
# currently every minute.
#
# 2. The external repo management script that plods through all the
# projects that have external repositories defined, clones or updates
# those external repos to their local locations, and if necessary
# registers them with the projects. This happens less often, currently
# every hour.

cd /var/www/code

mkdir -p reposman

for file in \
    convert-external-repos.rb \
    reposman-soundsoftware.rb \
    run-hginit.sh \
    update-external-repo.sh ; do
    if [ ! -f reposman/"$file" ]; then
        cp extra/soundsoftware/"$file" reposman/
    fi
done

for file in \
    run-external.sh \
    run-reposman.sh ; do
    if [ ! -f reposman/"$file" ]; then
        cp deploy/config/"$file".gen reposman/"$file"
    fi
done

chown code.www-data reposman/*
chmod +x reposman/*.sh
chmod +x reposman/*.rb

touch /var/log/reposman.log
touch /var/log/external-repos.log
chown www-data.code /var/log/reposman.log
chown www-data.code /var/log/external-repos.log

