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

doxyfile=`find "$hgdir" -type f -name Doxyfile -print | head -1`

echo "This project contains a Doxyfile:"
echo "$doxyfile"

if [ -z "$doxyfile" ]; then
    echo "No Doxyfile: skipping"
else

# hmm. should be a whitelist

    ( cd "$hgdir" && grep -vi OUTPUT_DIRECTORY "$doxyfile" | grep -vi HTML_OUTPUT | sed -e '$a OUTPUT_DIRECTORY='"$docdir" -e '$a HTML_OUTPUT = .' | doxygen - )

fi

# This is very rough; check what is actually permitted for package
# declarations

java_packages=`find "$hgdir" -type f -name \*.java -print | \
    xargs grep -h '^ *package [a-zA-Z][a-zA-Z0-9\._-]* *; *' | \
    sort | uniq | \
    sed -e 's/^ *package //' -e 's/ *; *$//'`

echo "This project contains Java packages:"
echo "$java_packages"

if [ -z "$java_packages" ]; then
    echo "No Java packages: skipping"
    exit 0
fi

# This won't work if code is in a subdir,
# e.g. src/com/example/project/Hello.java

# We need to convert the package name back to a path, and check
# whether that matches the tail of the path to a java file that
# declares itself to be in that package... but we don't have that list
# of java files to hand here... hm

javadoc -sourcepath "$hgdir" -d . -subpackages $java_packages -verbose

# If we have just written something to a doc directory that was
# previously empty, we should switch on Embedded for this project
