#!/bin/bash

set -e

# Initialise directories used as targets for cron activity (if they
# don't already exist)

# Reminder: the webapp directory is owned and run by the code user, in
# group www-data. The repos and other things served directly are
# usually the other way around -- owned by the www-data user, in group
# code. I don't recall whether there is a good reason for this.

for dir in \
    /var/files/backups \
    /var/doc \
    /var/files/code \
    /var/files/git-mirror ; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chown -R code.www-data "$dir"
        chmod g+s "$dir"
    fi
done

for dir in \
    /var/mirror ; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        chown -R www-data.code "$dir"
        chmod g+s "$dir"
    fi
done

if [ ! -e /var/www/code/files ]; then
    ln -s /var/files/code /var/www/code/files
fi
