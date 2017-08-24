#!/bin/bash

mydir=$(dirname "$0")
case "$mydir" in
    /*) ;;
    *) mydir=$(echo "$(pwd)/$mydir" | sed 's,/\./,/,g')
esac

if [ "$mydir" != "/code-to-deploy/deploy/any" ]; then
    echo "ERROR: Expected repository to be at /code-to-deploy prior to provisioning"
    echo "       (My directory is $mydir, expected /code-to-deploy/deploy/any)"
    exit 2
fi

set -e

. "$mydir"/prepare.sh

for f in "$mydir"/../provision.d/[0-9]*.sh ; do
    case "$f" in
        *~) ;;
        *) echo "Running provisioning script: $f"
           /bin/bash "$f";;
    esac
done

echo "All provisioning scripts complete"
