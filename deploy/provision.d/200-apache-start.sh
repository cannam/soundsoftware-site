#!/bin/bash

set -e

# Last action: check & start the webserver

apache2ctl configtest

apache2ctl restart

