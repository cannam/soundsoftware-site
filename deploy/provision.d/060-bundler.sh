#!/bin/bash

set -e

# Install Ruby gems for the web app.

# We aim to make all of these provisioning scripts non-destructive if
# run more than once. In this case, running the script again will
# install any outstanding updates.

cd /var/www/code
gem install bundler
bundle install

