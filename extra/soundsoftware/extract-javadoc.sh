#!/bin/sh

# Run this script from /var/doc/<project-name>

# Find Hg repo and update it

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


# This is very rough; check what is actually permitted for package
# declarations

java_packages=`find "$hgdir" -type f -name \*.java -print | \
     xargs grep -h '^ *package [a-zA-Z][a-zA-Z0-9\._-]* *; *' | sort | uniq | \
     sed -e 's/^ *package //' -e 's/ *; *$//'`

echo "This project contains java packages:"
echo "$java_packages"

# This won't work if code is in a subdir, e.g. src/com/example/project/Hello.java

javadoc -sourcepath "$hgdir" -d . -subpackages $java_packages -verbose

# If we have just written something to a doc directory that was
# previously empty, we should switch on Embedded for this project
