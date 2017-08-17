#!/bin/bash

set -e

# Copy reposman scripts to the place they actually live. Like docgen,
# this is particularly badly managed, since the target location is
# actually within the repo already. At least in this case some of the
# scripts have to be edited to insert the server's API key, so there
# is a bit of logic there

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
        ##!!! TODO: actually insert API key
        cat deploy/config/"$file".in > reposman/"$file"
    fi
done

chown code.www-data reposman/*
chmod +x reposman/*.sh
chmod +x reposman/*.rb

touch /var/log/reposman.log
touch /var/log/external-repos.log
chown www-data.code /var/log/reposman.log
chown www-data.code /var/log/external-repos.log

