#!/bin/bash

mydir=$(dirname "$0")
. "$mydir"/../any/prepare.sh

provisioning_commands=$(
    for x in "$deploydir"/provision.d/[0-9]*.sh; do
        echo "RUN /bin/bash /var/www/code/deploy/provision.d/$(basename $x)"
    done | sed 's/$/\\n/' | fmt -2000 | sed 's/ RUN/RUN/g' )

( echo
  echo "### DO NOT EDIT THIS FILE - it is generated from Dockerfile.in"
  echo
) > "$managerdir/Dockerfile"

cat "$managerdir/Dockerfile.in" |
    sed 's,INSERT_PROVISIONING_HERE,'"$provisioning_commands"',' >> \
        "$managerdir/Dockerfile.gen"

cd "$rootdir"

dockertag="cannam/soundsoftware-site"

sudo docker build -t "$dockertag" -f "deploy/docker/Dockerfile.gen" .
sudo docker run -p 8080:80 -d "$dockertag"

