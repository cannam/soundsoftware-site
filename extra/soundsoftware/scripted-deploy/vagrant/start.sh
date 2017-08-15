#!/bin/bash

dbpwd="$1"
if [ -z "$dbpwd" ]; then
    echo "Usage: $0 <database-password>" 1>&2
    exit 2
fi

set -eu

deploydir=./extra/soundsoftware/scripted-deploy
if [ ! -d "$deploydir" ]; then
    echo "Run this script from the root of a working copy of soundsoftware-site"
    exit 2
fi

managerdir="$deploydir/vagrant"
if [ ! -d "$managerdir" ]; then
    echo "ERROR: Required directory $managerdir not found"
    exit 2
fi

configdir="$deploydir/config"
if [ ! -d "$configdir" ]; then
    echo "ERROR: Required directory $configdir not found"
    exit 2
fi

if [ ! -f "postgres-dumpall" ]; then
    echo "ERROR: I expect to find a Postgres SQL multi-db dump file in ./postgres-dumpall"
    exit 2
fi

for f in database.yml code.conf ; do
    cat "$configdir/$f" |
        sed 's/INSERT_POSTGRES_PASSWORD_HERE/'"$dbpwd"'/g' > \
            "$configdir/$f.interpolated"
done

cd "$managerdir"

vagrant up

