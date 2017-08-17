#!/bin/bash

set -e

# Copy docgen scripts to the place they actually live. This is
# particularly badly managed, since the target location is actually
# within the repo already

cd /var/www/code

mkdir -p docgen

for file in \
    doxysafe.pl \
    extract-docs.sh \
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

chown code.www-data docgen/*
chmod +x docgen/*.sh

