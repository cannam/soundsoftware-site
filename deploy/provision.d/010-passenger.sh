#!/bin/bash

set -e

# Phusion Passenger as application server.
# This gets installed through gem, not apt, and we ask for a specific
# version (the last in the 4.0.x line).

if [ ! -f /var/lib/gems/2.3.0/gems/passenger-4.0.60/buildout/apache2/mod_passenger.so ]; then
    gem install passenger -v 4.0.60 --no-rdoc --no-ri
    passenger-install-apache2-module --languages=ruby
fi

