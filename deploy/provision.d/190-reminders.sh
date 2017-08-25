#!/bin/bash

set -e

# Print reminders of the things that we haven't covered in the deploy
# scripts

cat <<EOF

*** APACHE SSL CONFIGURATION

    The provisioning scripts set up a simple HTTP site only. Refer to
    code-ssl.conf for an example HTTPS configuration (you will of
    course need to provide the key/cert files).

*** SMOKE TEST

    There is a smoke test script in the deploy/test directory. That
    is, a quick automated acceptance test that checks that basic
    services are returning successful HTTP codes. Consider running it
    against this server from another host, i.e. not just localhost.

*** EMAIL

    Outgoing email is required for notifications, but has not been
    configured as part of this provisioning setup.

*** STATIC FRONT PAGE

    We have set up only the code/repository site -- if you want a
    separate front page, remember to configure that!

EOF
