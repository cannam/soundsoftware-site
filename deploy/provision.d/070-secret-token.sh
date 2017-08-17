#!/bin/bash

set -e

# Create a session token if it hasn't already been created.

cd /var/www/code

if [ ! -f config/initializers/secret_token.rb ]; then
    bundle exec rake generate_secret_token
fi


