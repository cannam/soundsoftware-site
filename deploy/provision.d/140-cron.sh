#!/bin/bash

set -e

# Copy cron scripts to the appropriate destinations

cd /var/www/code

if [ ! -d /etc/cron.minutely ]; then
    mkdir -p /etc/cron.minutely
    echo '*  *    * * *   root    test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.minutely )' >> /etc/crontab
fi

for t in minutely hourly daily monthly; do
    for s in deploy/config/cron.$t/[0-9]* ; do
        name=$(basename $s)
        dest="/etc/cron.$t/$name"
        if [ ! -f "$dest" ]; then
            cp "$s" "$dest"
            chmod +x "$dest"
        fi
    done
done


             
