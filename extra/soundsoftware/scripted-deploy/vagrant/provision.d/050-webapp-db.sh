#!/bin/bash

set -e

if [ ! -f /var/www/code/config/database.yml ]; then
    cp /var/www/code/extra/soundsoftware/scripted-deploy/config/database.yml.interpolated \
       /var/www/code/config/database.yml
fi

