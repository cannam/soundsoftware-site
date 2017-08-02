#!/bin/bash

set -eu

dockerdir=./extra/soundsoftware/dockertest
if [ ! -d "$dockerdir" ]; then
    echo "Run this script from the root of a working copy of soundsoftware-site"
    exit 2
fi

dockertag="cannam/soundsoftware-site"

sudo docker build -t "$dockertag" -f "$dockerdir/Dockerfile" .

