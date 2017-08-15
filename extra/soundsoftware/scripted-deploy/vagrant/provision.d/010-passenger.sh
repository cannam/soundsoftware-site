#!/bin/bash

set -e

# Passenger gets installed through gem, not apt

if [ ! -f /var/lib/gems/2.3.0/gems/passenger-4.0.60/buildout/apache2/mod_passenger.so ]; then
    gem install passenger -v 4.0.60 --no-rdoc --no-ri
    passenger-install-apache2-module --languages=ruby
fi

