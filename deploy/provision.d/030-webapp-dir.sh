#!/bin/bash

set -e

if [ ! -d /var/www/code ]; then
    if [ ! -d /code-to-deploy ]; then
        echo "ERROR: Expected to find code tree at /code-to-deploy: is the deployment script being invoked correctly?"
        exit 2
    fi
    cp -a /code-to-deploy /var/www/code
fi

chown -R code.www-data /var/www/code
find /var/www/code -type d -exec chmod g+s \{\} \;


