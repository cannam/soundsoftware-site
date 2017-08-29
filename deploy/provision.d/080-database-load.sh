#!/bin/bash

set -e

# Start the database and if a dump file is found, load it. The dump
# file is then deleted so that the db won't be overwritten on
# subsequent runs. (The original repo contains no dump file, so it
# should exist only if you have provided some data to load.)

/etc/init.d/postgresql start

cd "$rootdir"

if [ -f postgres-dumpall ]; then
    chmod ugo+r postgres-dumpall
    sudo -u postgres psql -f postgres-dumpall postgres
    rm postgres-dumpall
fi

