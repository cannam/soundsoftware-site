#!/bin/bash

set -e

# Install Apache config files and module loaders

cd /var/www/code

codeconffile=/var/www/code/deploy/config/code.conf

if [ ! -f "$codeconffile" ]; then
    echo "ERROR: Apache config file $codeconffile not found - has the database secret been interpolated from $codeconffile.in correctly?"
    exit 2
fi

if [ ! -f /etc/apache2/sites-enabled/10-code.conf ]; then
    
    rm -f /etc/apache2/sites-enabled/000-default.conf

    cp deploy/config/passenger.conf /etc/apache2/mods-available/
    cp deploy/config/passenger.load /etc/apache2/mods-available/
    cp deploy/config/perl.conf      /etc/apache2/mods-available/

    ln -s ../mods-available/passenger.conf  /etc/apache2/mods-enabled/
    ln -s ../mods-available/passenger.load  /etc/apache2/mods-enabled/
    ln -s ../mods-available/perl.conf       /etc/apache2/mods-enabled/
    ln -s ../mods-available/expires.load    /etc/apache2/mods-enabled/
    ln -s ../mods-available/rewrite.load    /etc/apache2/mods-enabled/
    ln -s ../mods-available/cgi.load        /etc/apache2/mods-enabled/

    cp "$codeconffile" /etc/apache2/sites-available/code.conf
    ln -s ../sites-available/code.conf /etc/apache2/sites-enabled/10-code.conf

    apache2ctl configtest

fi

