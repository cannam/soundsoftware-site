#!/bin/bash

set -e

if ! grep -q '^code:' /etc/passwd ; then
    groupadd code
    useradd -g code -G www-data code
fi

