#!/bin/bash

mydir=$(dirname "$0")

dbpwd="$1"
if [ -z "$dbpwd" ]; then
    echo "Usage: $0 <database-password>" 1>&2
    exit 2
fi

set -eu -o pipefail

rootdir="$mydir/../.."

deploydir="$rootdir"/deploy
if [ ! -d "$deploydir" ]; then
    echo "ERROR: Unexpected repository layout - expected directory at $deploydir"
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

if [ ! -f "$rootdir/postgres-dumpall" ]; then
    echo "ERROR: I expect to find a Postgres SQL multi-db dump file in $rootdir/postgres-dumpall"
    exit 2
fi

fontdir="$rootdir"/public/themes/soundsoftware/stylesheets/fonts
if [ ! -f "$fontdir/24BC0E_0_0.woff" ]; then
    echo "ERROR: I expect to find necessary webfonts in $fontdir"
    exit 2
fi

for f in database.yml code.conf ; do
    cat "$configdir/$f.in" |
        sed 's/INSERT_POSTGRES_PASSWORD_HERE/'"$dbpwd"'/g' > \
            "$configdir/$f"
done

cd "$managerdir"

vagrant up

