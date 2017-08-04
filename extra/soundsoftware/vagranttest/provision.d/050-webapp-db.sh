#!/bin/bash

set -e

#!!! This will fail until we have the user-supplied password
#!!! interpolation logic (also the path is silly)

if [ ! -f /var/www/code/config/database.yml ]; then
    cp /var/www/code/extra/soundsoftware/dockertest/database.yml.interpolated \
       /var/www/code/config/database.yml
fi

