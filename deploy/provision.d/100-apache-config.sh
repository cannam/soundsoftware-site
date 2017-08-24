#!/bin/bash

set -e

# Install Apache config files and module loaders

cd /var/www/code

codeconf=/var/www/code/deploy/config/code.conf.gen
codeconfssl=/var/www/code/deploy/config/code-ssl.conf.gen

if [ ! -f "$codeconf" ]; then
    echo "ERROR: Apache config file $codeconf not found - has the database secret been interpolated from its input file correctly?"
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
    ln -s ../mods-available/ssl.load        /etc/apache2/mods-enabled/

    cp "$codeconf" /etc/apache2/sites-available/code.conf
    cp "$codeconfssl" /etc/apache2/sites-available/code-ssl.conf
    ln -s ../sites-available/code.conf /etc/apache2/sites-enabled/10-code.conf

    apache2ctl configtest

fi

