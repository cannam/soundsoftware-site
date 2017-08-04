#!/bin/bash

set -e

cd /var/www/code

#!!! This will fail until we have the user-supplied password
#!!! interpolation logic (also the source paths are silly)

if [ ! -f /etc/apache2/sites-enabled/10-code.conf ]; then
    
    rm -f /etc/apache2/sites-enabled/000-default.conf

    cp extra/soundsoftware/dockertest/passenger.conf /etc/apache2/mods-available/
    cp extra/soundsoftware/dockertest/passenger.load /etc/apache2/mods-available/
    cp extra/soundsoftware/dockertest/perl.conf      /etc/apache2/mods-available/

    ln -s ../mods-available/passenger.conf  /etc/apache2/mods-enabled/
    ln -s ../mods-available/passenger.load  /etc/apache2/mods-enabled/
    ln -s ../mods-available/perl.conf       /etc/apache2/mods-enabled/
    ln -s ../mods-available/expires.load    /etc/apache2/mods-enabled/
    ln -s ../mods-available/rewrite.load    /etc/apache2/mods-enabled/
    ln -s ../mods-available/cgi.load        /etc/apache2/mods-enabled/

    cp extra/soundsoftware/dockertest/code.conf.interpolated /etc/apache2/sites-available/code.conf
    ln -s ../sites-available/code.conf /etc/apache2/sites-enabled/10-code.conf

    apache2ctl configtest

fi

