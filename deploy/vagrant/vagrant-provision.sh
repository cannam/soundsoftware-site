#!/bin/bash

#!!! still not covered:
# * https
# * http auth for API (/sys) and /admin interfaces
# * API keys and http auth for reposman and docgen

set -e

for f in /code-to-deploy/deploy/provision.d/[0-9]*.sh ; do
    case "$f" in
        *~) ;;
        *) echo "Running provision script: $f"
           /bin/bash "$f";;
    esac
done

