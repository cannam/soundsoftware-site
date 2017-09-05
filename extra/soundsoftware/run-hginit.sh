#!/bin/sh
location="$1"
hg init "$location" && mkdir "$location/.hg/store/data"
