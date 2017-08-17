#!/bin/bash

set -e

# The webapp directory is owned and run by the code user, in group
# www-data. The repos and other things served directly are the other
# way around -- owned by the www-data user, in group code.

for user in code docgen ; do
    if ! grep -q "^$user:" /etc/passwd ; then
        groupadd "$user"
        useradd -g "$user" -G www-data "$user"
    fi
done

