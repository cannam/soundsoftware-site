#!/bin/bash

set -e

# In case we are running without a properly mounted /var/hg directory,
# check for the existence of one repo and, if absent, attempt to clone
# it so that we have something we can serve for test purposes.

if [ ! -d /var/hg/vamp-plugin-sdk ]; then
    echo "Cloning vamp-plugin-sdk repo for testing..."
    cd /var/hg
    hg clone https://code.soundsoftware.ac.uk/hg/vamp-plugin-sdk
    chown -R code.www-data vamp-plugin-sdk
fi
