#!/bin/sh

# Run this script from /var/doc/<project-name>

# Find Hg repo and update it.  We should separate this process into
# two, first the update (run as www-data) and then the extraction (run
# as an otherwise totally unprivileged user without write permission
# on www-data/code stuff)

docdir=$(pwd)
name=$(basename $(pwd))
hgdir="/var/hg/$name"
echo "Extracting doc for $name"
if [ ! -d "$hgdir" ]; then
   echo "Error: No $hgdir found for project $name"
   exit 1
fi
( cd "$hgdir" ; hg update ) || exit 1

# Identify either a Doxyfile or some Java packages

# TODO: Doxyfile

doxyfile=`find "$hgdir" -type f -name Doxyfile -print | head -1`

if [ -z "$doxyfile" ]; then
    echo "No Doxyfile: skipping"
else
    echo "This project contains a Doxyfile:"
    echo "$doxyfile"


# hmm. should be a whitelist

    ( cd "$hgdir" && grep -vi OUTPUT_DIRECTORY "$doxyfile" | grep -vi HTML_OUTPUT | grep -vi SEARCHENGINE | grep -vi HAVE_DOT | grep -vi DOT_FONTNAME | grep -vi DOT_FONTPATH | grep -vi DOT_TRANSPARENT | \
	sed -e '$a OUTPUT_DIRECTORY='"$docdir" -e '$a HTML_OUTPUT = .' -e '$a SEARCHENGINE = NO' -e '$a HAVE_DOT = YES' -e '$a DOT_FONTNAME = FreeMono' -e '$a DOT_FONTPATH = /usr/share/fonts/truetype/freefont' -e '$a DOT_TRANSPARENT = YES' | doxygen - )

fi

# Identify Java files whose packages match the trailing parts of their
# paths, and list the resulting packages and the path prefixes with
# the packages removed (so as to find code in subdirs,
# e.g. src/com/example/...)

# Regexp match is very rough; check what is actually permitted for
# package declarations

find "$hgdir" -type f -name \*.java -exec grep '^ *package [a-zA-Z][a-zA-Z0-9\._-]*; *$' \{\} /dev/null \; |
    sed -e 's/\/[^\/]*: *package */:/' -e 's/; *$//' |
    sort | uniq | (
	current_prefix=
	current_packages=
	while IFS=: read filepath package; do 
	    echo "Looking at $package in $filepath"
	    packagepath=${package//./\/}
	    prefix=${filepath%$packagepath}
	    prefix=${prefix:=$hgdir}
	    if [ "$prefix" = "$filepath" ]; then
		echo "Package $package does not match suffix of path $filepath, skipping"
		continue
	    fi
	    if [ "$prefix" != "$current_prefix" ]; then
		if [ -n "$current_packages" ]; then
		    echo "Running Javadoc for packages $current_packages from prefix $current_prefix"
		    javadoc -sourcepath "$current_prefix" -d . -subpackages $current_packages
		fi
		current_prefix="$prefix"
		current_packages=
	    else
		current_packages="$current_packages $package"
	    fi
	done
	prefix=${prefix:=$hgdir}
	if [ -n "$current_packages" ]; then
	    echo "Running Javadoc for packages $current_packages in prefix $current_prefix"
	    javadoc -sourcepath "$current_prefix" -d . -subpackages $current_packages
	fi
    )

# This is very rough; check what is actually permitted for package
# declarations

# java_packages=`find "$hgdir" -type f -name \*.java -print | \
#     xargs grep -h '^ *package [a-zA-Z][a-zA-Z0-9\._-]* *; *' | \
#     sort | uniq | \
#     sed -e 's/^ *package //' -e 's/ *; *$//'`

# echo "This project contains Java packages:"
# echo "$java_packages"

# if [ -z "$java_packages" ]; then
#     echo "No Java packages: skipping"
#     exit 0
# fi


# # This won't work if code is in a subdir,
# # e.g. src/com/example/project/Hello.java

# # We need to convert the package name back to a path, and check
# # whether that matches the tail of the path to a java file that
# # declares itself to be in that package... but we don't have that list
# # of java files to hand here... hm

# javadoc -sourcepath "$hgdir" -d . -subpackages $java_packages -verbose

# # If we have just written something to a doc directory that was
# # previously empty, we should switch on Embedded for this project
