#!/bin/bash

set -e

if [ ! -d /var/www/code ]; then
    cp -a /vagrant-code /var/www/code
    chown -R code.www-data /var/www/code
    find /var/www/code -type d -exec chmod g+s \{\} \;
fi

