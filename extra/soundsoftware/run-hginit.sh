#!/bin/sh
location="$1"
hg init "$location" && mkdir "$location/.hg/store/data" && chown -R www-data.code "$location" && chmod g+s "$location"
