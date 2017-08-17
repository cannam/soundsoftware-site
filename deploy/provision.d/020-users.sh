#!/bin/bash

set -e

# The "code" user (in group www-data) owns the site and repo
# directories.

if ! grep -q '^code:' /etc/passwd ; then
    groupadd code
    useradd -g code -G www-data code
fi

