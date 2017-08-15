#!/bin/bash

set -e

if [ ! -f /var/hg/index.cgi ]; then
    mkdir -p /var/hg
    chown code.www-data /var/hg
    chmod g+s /var/hg
    cp /var/www/code/extra/soundsoftware/scripted-deploy/config/index.cgi /var/hg/
    cp /var/www/code/extra/soundsoftware/scripted-deploy/config/hgweb.config /var/hg/
    chmod +x /var/hg/index.cgi
fi

if [ ! -d /var/hg/vamp-plugin-sdk ]; then
    # This project can be used for testing
    cd /var/hg
    hg clone https://code.soundsoftware.ac.uk/hg/vamp-plugin-sdk
    chown -R code.www-data vamp-plugin-sdk
fi
