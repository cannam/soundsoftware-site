#!/bin/bash

set -e

cd /var/www/code

for t in minutely hourly daily monthly; do
    for s in deploy/config/cron.$t/[0-9]* ; do
        name=$(basename $s)
        actual="/etc/cron.$t/$name"
        echo "Running cron script $actual..."
        "$actual"
    done
done
