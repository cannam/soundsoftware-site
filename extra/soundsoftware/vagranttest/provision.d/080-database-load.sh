#!/bin/bash

set -e

/etc/init.d/postgresql start

cd /var/www/code

if [ -f postgres-dumpall ]; then
    chmod ugo+r postgres-dumpall
    sudo -u postgres psql -f postgres-dumpall postgres
    rm postgres-dumpall # This was just a copy of the shared folder file anyway
fi



