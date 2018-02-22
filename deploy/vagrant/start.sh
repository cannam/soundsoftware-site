#!/bin/bash

mydir=$(dirname "$0")
. "$mydir"/../any/prepare.sh

cd "$managerdir"
vagrant up

