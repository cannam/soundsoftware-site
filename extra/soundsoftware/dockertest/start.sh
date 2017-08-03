#!/bin/bash

dbpwd="$1"
if [ -z "$dbpwd" ]; then
    echo "Usage: $0 <database-password>" 1>&2
    exit 2
fi

set -eu

dockerdir=./extra/soundsoftware/dockertest
if [ ! -d "$dockerdir" ]; then
    echo "Run this script from the root of a working copy of soundsoftware-site"
    exit 2
fi

for f in database.yml code.conf ; do
    cat "$dockerdir/$f" |
        sed 's/INSERT_POSTGRES_PASSWORD_HERE/'"$dbpwd"'/g' > \
            "$dockerdir/$f.interpolated"
done

dockertag="cannam/soundsoftware-site"

sudo docker build -t "$dockertag" -f "$dockerdir/Dockerfile" .
sudo docker run -p 8080:80 -d "$dockertag"

