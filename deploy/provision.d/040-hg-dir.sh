#!/bin/bash

set -e

# In a real deployment, /var/hg is probably mounted from somewhere
# else. But in an empty deployment we need to create it, and in both
# cases we set up the config files with their current versions here.

if [ ! -f /var/hg/index.cgi ]; then
    mkdir -p /var/hg
fi

cp /var/www/code/deploy/config/index.cgi /var/hg/
cp /var/www/code/deploy/config/hgweb.config /var/hg/

chmod +x /var/hg/index.cgi

chown -R code.www-data /var/hg
find /var/hg -type d -exec chmod g+s \{\} \;

