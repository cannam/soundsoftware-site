#!/bin/bash

set -e

cd /var/www/code
gem install bundler
bundle install

