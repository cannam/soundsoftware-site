#!/bin/bash

set -e

cd /var/www/code
bundle exec rake generate_secret_token

