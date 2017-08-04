#!/bin/bash

set -e

if [ ! -f /var/hg/index.cgi ]; then
    mkdir -p /var/hg
    chown code.www-data /var/hg
    chmod g+s /var/hg
    cp /var/www/code/extra/soundsoftware/dockertest/index.cgi /var/hg/
    cp /var/www/code/extra/soundsoftware/dockertest/hgweb.config /var/hg/
    chmod +x /var/hg/index.cgi
fi

