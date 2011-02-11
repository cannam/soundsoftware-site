#!/bin/bash

# Run this script from anywhere

# Enumerate Hg repos; make sure they're up to date; extract docs for
# each

hgdir="/var/hg"
docdir="/var/doc"

apikey=""
apihost=""
apiuser=""
apipass=""

progdir=$(dirname $0)
case "$progdir" in
    /*) ;;
    *) progdir="$(pwd)/$progdir" ;;
esac

types="javadoc doxygen"

for x in $types; do
    if [ ! -x "$progdir/extract-$x.sh" ]; then
	echo "Helper script not available: $progdir/extract-$x.sh"
	exit 1
    fi
done

enable_embedded()
{
    p="$1"
    if [ -n "$apiuser" ]; then
	curl -u "$apiuser":"$apipass" "http://$apihost/sys/projects/$p/embedded.xml?enable=1&key=$apikey" -d ""
    else
	curl "http://$apihost/sys/projects/$p/embedded.xml?enable=1&key=$apikey" -d ""
    fi
}

for projectdir in "$hgdir"/* ; do

    if [ -d "$projectdir" ] && [ -d "$projectdir/.hg" ]; then

	project=$(basename "$projectdir")
	echo "Found Hg repo: $projectdir for project $project"

 ##!!! do as www-data:
	( cd "$projectdir" ; sudo -u www-data hg -q update ) || exit 1

	tmpdir=$(mktemp -d "$docdir/tmp_XXXXXX")
	
	case "$tmpdir" in
	    /*) ;;
	    *) echo "Temporary directory creation failed"; exit 1;;
	esac

	targetdir="$docdir/$project"

	echo "Temporary dir is $tmpdir, eventual target is $targetdir"

 ##!!! do as docs user:
	for x in $types; do
	    if "$progdir/extract-$x.sh" "$project" "$tmpdir"; then
		break
	    else
		echo "Failed to extract via type $x"
	    fi
	done

        if [ -f "$tmpdir/index.html" ]; then
	    echo "Processing resulted in an index.html being created, looks good!"
	    if [ ! -d "$targetdir" ] || [ ! -f "$targetdir/index.html" ]; then
# # If we have just written something to a doc directory that was
# # previously empty, we should switch on Embedded for this project
		echo "This project hasn't had doc extracted before -- I should switch on Embedded for it at this point"
		enable_embedded "$project"
	    fi

	    if [ -d "$targetdir" ]; then
		mv "$targetdir" "$targetdir"_"$$" && \
		    mv "$tmpdir" "$targetdir" && \
		    rm -rf "$targetdir"_"$$"
	    else 
		echo "Processing resulted in no index.html, skipping"
		mv "$tmpdir" "$targetdir"
	    fi

	else
	    # generated nothing (useful)
	    rm -rf "$tmpdir"
	fi
    fi
done

