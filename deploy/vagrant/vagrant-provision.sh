#!/bin/bash

set -e

for f in /code-to-deploy/deploy/provision.d/[0-9]*.sh ; do
    case "$f" in
        *~) ;;
        *) echo "Running provisioning script: $f"
           /bin/bash "$f";;
    esac
done

echo "All provisioning scripts complete"
