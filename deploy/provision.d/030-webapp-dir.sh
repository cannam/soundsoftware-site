#!/bin/bash

set -e

# We might be running in one of two ways:
#
# 1. The code directory is already at /var/www/code, either because a
# previous provisioning step has imported it there or because this
# script has been run before -- in this situation all we do is
# re-check the ownership and permissions. OR
#
# 2. The code directory has not yet been copied to /var/www/code, in
# which case we expect to find it at /code-to-deploy, e.g. as a
# Vagrant shared folder, and we copy it over from there. (We don't
# deploy directly from shared folders as we might not be able to
# manipulate ownership and permissions properly there.)

if [ ! -d /var/www/code ]; then
    if [ ! -d /code-to-deploy ]; then
        echo "ERROR: Expected to find code tree at /var/www/code or /code-to-deploy: is the deployment script being invoked correctly?"
        exit 2
    fi
    cp -a /code-to-deploy /var/www/code
fi

chown -R code.www-data /var/www/code
chmod 755 /var/www/code
find /var/www/code -type d -exec chmod g+s \{\} \;

