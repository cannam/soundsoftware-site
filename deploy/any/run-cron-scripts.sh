#!/bin/bash

set -e

cd /var/www/code

for t in minutely hourly daily monthly; do
    for s in deploy/config/cron.$t/[0-9]* ; do
        name=$(basename $s)
        actual="/etc/cron.$t/$name"
        echo "Running cron script $actual..."
        if "$actual"; then
            echo "Cron script $actual ran successfully"
        else
            echo "Cron script $actual failed with error code $?"
            exit 1
        fi
    done
done
