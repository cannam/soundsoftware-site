#!/bin/bash

set -e

# Copy docgen scripts, including the generated scripts with
# interpolated API key etc, to the directory they will be run from.

# These are run from cron jobs to do the (currently daily) update of
# extracted documentation from Doxygen, Javadoc, and MATLAB, and to
# enable displaying them with the redmine_embedded plugin. (The API
# key is needed to automatically switch on the embedded module for a
# project the first time its docs are extracted.)

cd /var/www/code

mkdir -p docgen

for file in \
    doxysafe.pl \
    extract-doxygen.sh \
    extract-javadoc.sh \
    extract-matlabdocs.sh \
    matlab-docs.conf \
    matlab-docs-credit.html \
    matlab-docs.pl ; do
    if [ ! -f docgen/"$file" ]; then
        cp extra/soundsoftware/"$file" docgen/
    fi
done

for file in \
    extract-docs.sh ; do
    if [ ! -f docgen/"$file" ]; then
        cp deploy/config/"$file".gen docgen/"$file"
    fi
done

chown code.www-data docgen/*
chmod +x docgen/*.sh

