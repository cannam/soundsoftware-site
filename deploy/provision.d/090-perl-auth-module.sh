#!/bin/bash

set -e

# Install the Apache mod_perl module used for hg repo access control

if [ ! -f /usr/local/lib/site_perl/Apache/Authn/SoundSoftware.pm ]; then
    mkdir -p /usr/local/lib/site_perl/Apache/Authn/
    cp /var/www/code/extra/soundsoftware/SoundSoftware.pm \
       /usr/local/lib/site_perl/Apache/Authn/
fi

