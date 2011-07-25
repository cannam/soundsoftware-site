#!/bin/bash

docdir="/var/doc"

project="$1"
projectdir="$2"
targetdir="$3"

if [ -z "$project" ] || [ -z "$targetdir" ] || [ -z "$projectdir" ]; then
    echo "Usage: $0 <project> <projectdir> <targetdir>"
    exit 2
fi

if [ ! -d "$projectdir" ]; then
    echo "Project directory $projectdir not found"
    exit 1
fi

if [ ! -d "$targetdir" ]; then
    echo "Target dir $targetdir not found"
    exit 1
fi

if [ -f "$targetdir/index.html" ]; then
    echo "Target dir $targetdir already contains index.html"
    exit 1
fi

# Identify Java files whose packages match the trailing parts of their
# paths, and list the resulting packages and the path prefixes with
# the packages removed (so as to find code in subdirs,
# e.g. src/com/example/...)

# Regexp match is very rough; check what is actually permitted for
# package declarations

find "$projectdir" -type f -name \*.java \
    -exec grep '^ *package [a-zA-Z][a-zA-Z0-9\._-]*; *$' \{\} /dev/null \; |
    sed -e 's/\/[^\/]*: *package */:/' -e 's/; *$//' |
    sort | uniq | (
	current_prefix=
	current_packages=
	while IFS=: read filepath package; do 
	    echo "Looking at $package in $filepath"
	    packagepath=${package//./\/}
	    prefix=${filepath%$packagepath}
	    prefix=${prefix:=$projectdir}
	    if [ "$prefix" = "$filepath" ]; then
		echo "Package $package does not match suffix of path $filepath, skipping"
		continue
	    fi
	    if [ "$prefix" != "$current_prefix" ]; then
		echo "Package $package matches file path and has new prefix $prefix"
		if [ -n "$current_packages" ]; then
		    echo "Running Javadoc for packages $current_packages from prefix $current_prefix"
		    echo "Command is: javadoc -sourcepath "$current_prefix" -d "$targetdir" -subpackages $current_packages"
		    javadoc -sourcepath "$current_prefix" -d "$targetdir" -subpackages $current_packages
		fi
		current_prefix="$prefix"
		current_packages="$package"
	    else
		echo "Package $package matches file path with same prefix as previous file"
		current_packages="$current_packages $package"
	    fi
	done
	prefix=${prefix:=$projectdir}
	if [ -n "$current_packages" ]; then
	    echo "Running Javadoc for packages $current_packages in prefix $current_prefix"
  	    echo "Command is: javadoc -sourcepath "$current_prefix" -d "$targetdir" -subpackages $current_packages"
	    javadoc -sourcepath "$current_prefix" -d "$targetdir" -subpackages $current_packages
	fi
    )

if [ -f "$targetdir"/overview-tree.html ]; then
    cp "$targetdir"/overview-tree.html "$targetdir"/index.html
fi

# for exit code:
[ -f "$targetdir/index.html" ]

