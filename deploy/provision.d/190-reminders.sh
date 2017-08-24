#!/bin/bash

set -e

# Print reminders of the things that we haven't covered in the deploy
# scripts

cat <<EOF

*** APACHE SSL CONFIGURATION

    The provisioning scripts set up a simple HTTP site only. Refer to
    deploy/config/code-ssl.conf.in for an example HTTPS configuration
    (you will of course need to provide the key/cert files).

*** EMAIL

    Outgoing email is required for notifications, but has not been
    configured as part of this provisioning setup.

*** STATIC FRONT PAGE

    We have set up only the code/repository site -- if you want a
    separate front page, remember to configure that!

EOF
