#!/bin/bash

# To be sourced into a container-specific start.sh file, not run
# standalone

usage() {
    echo "Usage: $0 <database-password> <api-key> <api-httpauth-password>" 1>&2
    exit 2
}

dbpass="$1"
if [ -z "$dbpass" ]; then
    usage
fi

apikey="$2"
if [ -z "$apikey" ]; then
    usage
fi

apipass="$3"
if [ -z "$apipass" ]; then
    usage
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
    echo "ERROR: I expect to find a Postgres SQL multi-db dump file in $rootdir/postgres-dumpall. Create an empty file there if you don't want to load a database."
    exit 2
fi

fontdir="$rootdir"/public/themes/soundsoftware/stylesheets/fonts
if [ ! -f "$fontdir/24BC0E_0_0.woff" ]; then
    echo "ERROR: I expect to find necessary webfonts in $fontdir"
    exit 2
fi

apischeme=http
apihost=localhost

#apischeme=https
#apihost=code.soundsoftware.ac.uk

for f in "$configdir"/*.in "$rootdir"/extra/soundsoftware/extract-docs.sh ; do
    out="$configdir"/$(basename "$f" .in).gen
    cat "$f" | sed \
                   -e 's/INSERT_DATABASE_PASSWORD_HERE/'"$dbpass"'/g' \
                   -e 's/INSERT_API_KEY_HERE/'"$apikey"'/g' \
                   -e 's/INSERT_API_SCHEME_HERE/'"$apischeme"'/g' \
                   -e 's/INSERT_API_HOST_HERE/'"$apihost"'/g' \
                   -e 's/INSERT_API_USER_HERE/user/g' \
                   -e 's/INSERT_API_PASSWORD_HERE/'"$apipass"'/g' \
                   > "$out"
done
