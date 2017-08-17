#!/bin/bash

set -e

if [ ! -d /var/hg/vamp-plugin-sdk ]; then
    # This project can be used for testing
    echo "Cloning vamp-plugin-sdk repo for testing..."
    cd /var/hg
    hg clone https://code.soundsoftware.ac.uk/hg/vamp-plugin-sdk
    chown -R code.www-data vamp-plugin-sdk
fi
