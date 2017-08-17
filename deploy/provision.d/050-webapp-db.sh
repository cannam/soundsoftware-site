#!/bin/bash

set -e

# Copy across the database config file (the source file has presumably
# been generated from a skeleton, earlier in provisioning)

infile=/var/www/code/deploy/config/database.yml
outfile=/var/www/code/config/database.yml

if [ ! -f "$outfile" ]; then
    if [ ! -f "$infile" ]; then
        echo "ERROR: Database config file $infile not found - has the database secret been interpolated from $infile.in correctly?"
        exit 2
    fi
    cp "$infile" "$outfile"
fi

