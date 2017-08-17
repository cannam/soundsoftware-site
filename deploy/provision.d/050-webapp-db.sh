#!/bin/bash

set -e

infile=/var/www/code/deploy/config/database.yml

if [ ! -f "$infile" ]; then
    echo "ERROR: Database config file $infile not found - has the database secret been interpolated from $infile.in correctly?"
    exit 2
fi

if [ ! -f /var/www/code/config/database.yml ]; then
    cp "$infile" /var/www/code/config/database.yml
fi

