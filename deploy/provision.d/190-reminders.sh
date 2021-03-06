#!/bin/bash

set -e

# Print reminders of the things that we haven't covered in the deploy
# scripts

cat <<EOF

*** APACHE SSL CONFIGURATION

    The provisioning scripts set up a simple HTTP site only. Refer to
    code-ssl.conf for an example HTTPS configuration (you will of
    course need to provide the key/cert files).

*** CRON SCRIPTS

    A number of cron scripts have been installed. It might be no bad
    thing to prime and test them by running them all once now. Some of
    the services tested by the smoke test script (below) may depend on
    their having run. Use deploy/any/run-cron-scripts.sh for this.

*** SMOKE TEST

    There is a smoke test script in the deploy/test directory. That
    is, a quick automated acceptance test that checks that basic
    services are returning successful HTTP codes. Consider running it
    against this server from another host, i.e. not just localhost.

*** EMAIL

    Outgoing email is required for notifications, but has not been
    configured as part of this provisioning setup. You'll need to set
    up the server's outgoing mail support and also edit the application
    email settings in config/configuration.yml.

*** CRON EMAIL

    Ensure the MAILTO value in /etc/crontab is set to something real.

*** STATIC FRONT PAGE

    We have set up only the code/repository site -- if you want a
    separate front page, remember to configure that!

EOF
