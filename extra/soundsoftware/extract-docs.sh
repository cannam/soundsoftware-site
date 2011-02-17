#!/bin/bash

# Run this script from anywhere

# Enumerate Hg repos; make sure they're up to date; extract docs for
# each

hgdir="/var/hg"
docdir="/var/doc"
logfile="/var/www/test-cannam/log/extract-docs.log"

redgrp="redmine"

apikey=""
apihost=""
apiuser=""
apipass=""

progdir=$(dirname $0)
case "$progdir" in
    /*) ;;
    *) progdir="$(pwd)/$progdir" ;;
esac

types="doxygen javadoc" # Do Doxygen first (it can be used for Java too)

for x in $types; do
    if [ ! -x "$progdir/extract-$x.sh" ]; then
	echo "Helper script not available: $progdir/extract-$x.sh"
	exit 1
    fi
done

enable_embedded()
{
    p="$1"
    if [ -n "$apikey" ]; then
	if [ -n "$apiuser" ]; then
	    sudo -u docgen curl -u "$apiuser":"$apipass" "http://$apihost/sys/projects/$p/embedded.xml?enable=1&key=$apikey" -d ""
	else
	    sudo -u docgen curl "http://$apihost/sys/projects/$p/embedded.xml?enable=1&key=$apikey" -d ""
	fi
    else 
	echo "Can't enable Embedded, API not configured" 1>&2
    fi
}

# We want to ensure the doc extraction is done by the unprivileged
# user docgen, which is not a member of any interesting group
# 
# To this end, we create the tmpdir with user docgen and group
# www-data, and use the www-data user to pull out an archive of the Hg
# repo tip into a location beneath that, before using the docgen user
# to extract docs from that location and write them into the tmpdir

# Same tmpdir for each project: we delete and recreate to avoid
# cleanup duty from lots of directories being created
#
tmpdir=$(mktemp -d "$docdir/tmp_XXXXXX")

fail()
{
    message="$1"
    echo "$message" 1>&2
    case "$tmpdir" in
	*/tmp*) rm -rf "$tmpdir";;
	*);;
    esac
    exit 1
}

case "$tmpdir" in
    /*) ;;
    *) fail "Temporary directory creation failed";;
esac

chown docgen.www-data "$tmpdir" || fail "Temporary directory ownership change failed"
chmod g+rwx "$tmpdir" || fail "Temporary directory permissions change failed"

for projectdir in "$hgdir"/* ; do

    if [ -d "$projectdir" ] && [ -d "$projectdir/.hg" ]; then

	if ! sudo -u www-data hg -R "$projectdir" -q update; then
	    echo "Failed to update Hg in $projectdir, skipping" 1>&2
	    continue
	fi

	project=$(basename "$projectdir")

	tmptargetdir="$tmpdir/doc"
	snapshotdir="$tmpdir/hgsnapshot"

	rm -rf "$tmptargetdir" "$snapshotdir"

	mkdir -m 770 "$tmptargetdir" || fail "Temporary target directory creation failed"
	chown docgen.www-data "$tmptargetdir" || fail "Temporary target directory ownership change failed"

	mkdir -m 770 "$snapshotdir" || fail "Snapshot directory creation failed"
	chown docgen.www-data "$snapshotdir" || fail "Snapshot directory ownership change failed"

	hgparents=$(sudo -u www-data hg -R "$projectdir" parents)
	if [ -z "$hgparents" ]; then
	    echo "Hg repo at $projectdir has no working copy (empty repo?), skipping"
	    continue
	else
	    echo "Found non-empty Hg repo: $projectdir for project $project"
	fi

	if ! sudo -u www-data hg -R "$projectdir" archive -r tip -t files "$snapshotdir"; then
	    echo "Failed to pick archive from $projectdir, skipping" 1>&2
	    continue
	fi

	targetdir="$docdir/$project"

	echo "Temporary dir is $tmpdir, temporary doc dir is $tmptargetdir, snapshot dir is $snapshotdir, eventual target is $targetdir"

	for x in $types; do
	    if sudo -u docgen "$progdir/extract-$x.sh" "$project" "$snapshotdir" "$tmptargetdir" >> "$logfile" 2>&1; then
		break
	    else
		echo "Failed to extract via type $x"
	    fi
	done

        if [ -f "$tmptargetdir/index.html" ]; then
	    echo "Processing resulted in an index.html being created, looks good!"
	    if [ ! -d "$targetdir" ] || [ ! -f "$targetdir/index.html" ]; then
		echo "This project hasn't had doc extracted before: enabling Embedded"
		enable_embedded "$project"
	    fi

	    if [ -d "$targetdir" ]; then
		mv "$targetdir" "$targetdir"_"$$" && \
		    mv "$tmptargetdir" "$targetdir" && \
		    rm -rf "$targetdir"_"$$"
		chgrp -R "$redgrp" "$targetdir"
	    else 
		mv "$tmptargetdir" "$targetdir"
		chgrp -R "$redgrp" "$targetdir"
	    fi
	else
	    echo "Processing did not result in an index.html being created"
	fi
    fi
done

rm -rf "$tmpdir"
