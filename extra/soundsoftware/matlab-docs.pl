@rem = '--*-Perl-*--';
@rem = '
@echo off
perl -w -S %0.bat %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
@rem ';
# perl -w -S %0.bat "$@"
#!/usr/bin/perl
#
# mtree2html_2000 - produce html files from Matlab m-files.
#                   use configuration file for flexibility
#                   can process tree of directories
#
# Copyright (C) 1996-2000 Hartmut Pohlheim.  All rights reserved.
# includes small parts of m2html from Jeffrey C. Kantor 1995
#
# Author:  Hartmut Pohlheim
# History: 06.03.1996  file created
#          07.03.1996  first working version
#          08.03.1996  modularized, help text only once included
#          11.03.1996  clean up, some functions rwritten
#          18.04.1996  silent output with writing in one line only
#                      version 0.20 fixed
#          14.05.1996  start of adding tree structure, could create tree
#          15.05.1996  creating of index files for every directory
#          17.05.1996  first working version except compact A-Z index
#          20.05.1996  cleanup of actual version, more variables and 
#                      configurable settings
#          21.05.1996  reading, update and creation of contents.m added 
#          22.05.1996  creation of short index started
#          28.05.1996  jump letters for short index,
#                      3 different directory indexes (short/long/contents)
#          29.05.1996  major cleanup, short and long index created from one function
#                      links for HTML and Indexes from 1 function,
#                      version 0.9
#          30.05.1996  contents.m changed to Contents.m (because unix likes it)
#                      function definition can be in first line of m file before comments
#                      version 0.91 fixed
#          03.06.1996  contents file can be written as wanted, the links will be correct
#                      cross references in help block of m-file will be found and
#                      converted, even if the name of the function is written upper case
#                      version 0.92 fixed
#          05.06.1996  construction of dependency matrix changed, is able now to process
#                      even the whole matlab tree (previous version needed to much memory)
#                      removed warning for contents files in different directories
#                      version 0.94 fixed
#          06.06.1996  new link name matrices for ConstructHTMLFile created,
#                      everything is done in ConstructDependencyMatrix,
#                      both dependencies (calls and called) and matrix 
#                      with all mentioned names in this m-file, thus, much
#                      less scanning in html construction
#                      script is now (nearly) linear scalable, thus, matlab-toolbox
#                      tree takes less than 1 hour on a Pentium120, with source
#                      version 0.96 fixed
#          10.06.1996  order of creation changed, first all indexes (includes 
#                      update/creation of contents.m) and then ConstructDepency
#                      thus, AutoAdd section will be linked as well
#                      excludenames extended, some more common word function names added
#                      version 0.97 fixed
#          17.02.1998  writecontentsm as command line parameter added
#                      error of file not found will even appear when silent
#                      version 1.02
#          21.05.2000  mark comments in source code specially (no fully correct, 
#                      can't handle % in strings)
#                      version 1.11
#          05.11.2000  link also to upper and mixed case m-files
#                      searching for .m files now really works (doesn't find grep.com any longer)
#                      file renamed to mtree2html2001
#                      generated html code now all lower case 
#                      inclusion of meta-description and meta-keywords in html files
#                      HTML4 compliance done (should be strict HTML4.0, quite near XHTML)
#                      version 1.23
#
#	   29.03.2011  (Chris Cannam) add frames option
#

$VERSION  = '1.23';
($PROGRAM = $0) =~ s@.*/@@; $PROGRAM = "\U$PROGRAM\E";
$debug = 0;

#------------------------------------------------------------------------
# Define platform specific things
#------------------------------------------------------------------------
# suffix for files to search is defined twice
# the first ($suffix) is for string creation and contains the . as well
# the second ($suffixforsearch) is for regular expression, handling of . is quite special
$suffix = ".m";
$suffixforsearch = "m";
# the directory separator
$dirsep = "/";
# what is the current directory
$diract = ".";

#------------------------------------------------------------------------
#  Define all variables and their standard settings
#  documentation of variables is contained in accompanying rc file
#------------------------------------------------------------------------
%var =
(
   'authorfile',                '',
   'codebodyfiles',             '',
   'codebodyindex',             '',
   'codeheadmeta',              '<meta name="author of conversion perl script" content="Hartmut Pohlheim" />',
   'codehr',                    '<hr size="3" noshade="noshade" />',
   'codeheader',                '',
   'configfile',                'mtree2html2001_rc.txt',
   'csslink',                   '',
   'dirmfiles',                 $diract,
   'dirhtml',                   $diract,
   'exthtml',                   '.html',
   'frames',                    'yes',
   'filenametopframe',          'index',
   'filenameindexlongglobal',   'indexlg',
   'filenameindexlonglocal',    'indexll',
   'filenameindexshortglobal',  'indexsg',
   'filenameindexshortlocal',   'indexsl',
   'filenameextensionframe',    'f',
   'filenameextensionindex',    'i',
   'filenameextensionjump',     'j',
   'filenamedirshort',          'dirtops',
   'filenamedirlong',           'dirtopl',
   'filenamedircontents',       'dirtopc',
   'includesource',             'yes',
   'links2filescase',           'all',
   'processtree',               'yes',
   'producetree',               'yes',
   'textjumpindexlocal',        'Local Index',
   'textjumpindexglobal',       'Global Index',
   'texttitleframelayout',      'Documentation of Matlab Files',
   'texttitleindexalldirs',     'Index of Directories',
   'textheaderindexalldirs',    'Index of Directories',
   'texttitleindex',            '',
   'textheaderindex',           '',
   'texttitlefiles',            'Documentation of ',
   'textheaderfiles',           'Documentation of ',
   'usecontentsm',              'yes',
   'writecontentsm',            'no'
);


# define all m-file names, that should be excluded from linking
# however, files will still be converted
@excludenames = ( 'all','ans','any','are',
                  'cs',
                  'demo','dos',
                  'echo','edit','else','elseif','end','exist',
                  'flag','for','function',
                  'global',
                  'help',
                  'i','if','inf','info',
                  'j',
                  'more',
                  'null',
                  'return',
                  'script','strings',
                  'what','which','while','who','whos','why',
                );

# Text for inclusion in created HTML/Frame files: Doctype and Charset
$TextDocTypeHTML  = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0//EN" "http://www.w3.org/TR/REC-html40/strict.dtd">';
$TextDocTypeFrame = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Frameset//EN" "http://www.w3.org/TR/REC-html40/frameset.dtd">'; 
$TextMetaCharset = '<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1" />';

#------------------------------------------------------------------------
# Read the command line arguments
#------------------------------------------------------------------------
if (@ARGV == 0) {
   &DisplayHelp()  if &CheckFileName($var{'configfile'}, 'configuration file');
}

# Print provided command line arguments on screen
foreach (@ARGV) { print "   $_\n      "; }

# Get the options
use Getopt::Long;
@options = ('help|h', 'todo|t', 'version|v',
            'authorfile|a=s', 'configfile|c=s', 'dirhtml|html|d=s',
            'dirmfiles|mfiles|m=s', 'includesource|i=s',
            'processtree|r=s', 'producetree|p=s',
            'silent|quiet|q', 'writecontentsm|w=s');
&GetOptions(@options) || die "use -h switch to display help statement\n";


# Display help or todo list, when requested
&DisplayHelp()                         if $opt_help;
&DisplayTodo()                         if $opt_todo;
die "$PROGRAM v$VERSION\n"             if $opt_version;

$exit_status = 0;

#------------------------------------------------------------------------
# Read the config file
#------------------------------------------------------------------------
$var{'configfile'} = $opt_configfile         if $opt_configfile;
&GetConfigFile($var{'configfile'});


#------------------------------------------------------------------------
# Process/Check the command line otions
#------------------------------------------------------------------------
$var{'dirhtml'}   = $opt_dirhtml              if $opt_dirhtml;
if (!(substr($var{'dirhtml'}, -1, 1) eq $dirsep)) { $var{'dirhtml'} = $var{'dirhtml'}.$dirsep; }
$var{'dirmfiles'} = $opt_dirmfiles            if $opt_dirmfiles;
if (!(substr($var{'dirmfiles'}, -1, 1) eq $dirsep)) { $var{'dirmfiles'} = $var{'dirmfiles'}.$dirsep; }

$var{'authorfile'} = $opt_author              if $opt_author;
$var{'includesource'} = $opt_includesource    if $opt_includesource;
if ($var{'includesource'} ne 'no') { $var{'includesource'} = 'yes'; }
$var{'processtree'} = $opt_processtree        if $opt_processtree;
if ($var{'processtree'} ne 'no') { $var{'processtree'} = 'yes'; }
$var{'producetree'} = $opt_producetree        if $opt_producetree;
if ($var{'producetree'} ne 'no') { $var{'producetree'} = 'yes'; }
if ($var{'processtree'} eq 'no') { $var{'producetree'} = 'no'; }
if ($var{'frames'} ne 'no') { $var{'frames'} = 'yes'; }
# if (($var{'processtree'} eq 'yes') && ($var{'producetree'} eq 'no')) { $var{'usecontentsm'} = 'no'; }

$var{'writecontentsm'} = $opt_writecontentsm  if $opt_writecontentsm;

#------------------------------------------------------------------------
# Do the real stuff
#------------------------------------------------------------------------

# Print variables on screen, when not silent
&ListVariables                          if !$opt_silent;

# Check the author file
if ($var{'authorfile'} ne '') {
   if (&CheckFileName($var{'authorfile'}, 'author file')) {
      $var{'authorfile'} = '';
      if (!$opt_silent) { print "   Proceeding without author information!\n"; }
   }
}

# Call the function doing all the real work
&ConstructNameMatrix;

&ConstructDependencyMatrix;

&ConstructAllIndexFiles;

&ConstructHTMLFiles;

exit $exit_status;

#------------------------------------------------------------------------
# Construct list of all mfile names and initialize various data arrays.
#------------------------------------------------------------------------
sub ConstructNameMatrix
{
   local(*MFILE);
   local($file, $dirname);
   local(@newdirectories);
   local(%localnames);
   
   $RecDeep = 0;
   &ParseTreeReadFiles($var{'dirmfiles'}, $RecDeep);

   foreach $dirname (@directories) { 
      if ($dirnumbermfiles{$dirname} > 0) {
         push(@newdirectories, $dirname);
         if (! defined($contentsname{$dirname})) {
            $contentsname{$dirname} = 'Contents';
            if (($var{'writecontentsm'} eq 'no') && ($var{'usecontentsm'} eq 'yes')) {
               print "\r ParseTree - for directory  $dirname  no contents file found!\n";
               print   "             create one or enable writing of contents file (writecontentsm = yes)!\n";
            }
         }
      }
   }
   @alldirectories = @directories;
   @directories = @newdirectories;

   foreach $dirname (@directories) { 
      if ($debug > 0) { print "Dir: $dirname \t\t $dirnumbermfiles{$dirname} \t$contentsname{$dirname}\n"; }
   }
   
   @names = sort(keys %mfile);

   # check, if name of directory is identical to name of file
   @dirsinglenames = values(%dirnamesingle);
   grep($localnames{$_}++, @dirsinglenames);
   @dirandfilename = grep($localnames{$_}, @names);
   if (@dirandfilename) { 
      print "\r   Name clash between directory and file name: @dirandfilename\n";
      print   "      These files will be excluded from linking!\n";
      push(@excludenames, @dirandfilename);
   }
   
   # construct names matrix for help text linking
   #    exclude some common words (and at the same time m-functions) from linking in help text
   grep($localnames{$_}++, @excludenames);
   @linknames = grep(!$localnames{$_}, @names);

   if ($debug > 2) { print "linknames (names of found m-files):\n    @linknames\n"; }
   
}

#------------------------------------------------------------------------
# Parse tree and collect all Files
#------------------------------------------------------------------------
sub ParseTreeReadFiles
{
   local($dirname, $localRecDeep) = @_;
   local($file, $name, $filewosuffix);
   local($dirhtmlname, $dirmode);
   local($relpath, $relpathtoindex, $replacevardir);
   local(*CHECKDIR, *AKTDIR);
   local(@ALLEFILES);
   
   opendir(AKTDIR, $dirname) || die "ParseTree - Can't open directory $dirname: $!";
   if ($debug > 1) { print "\nDirectory: $dirname\n"; }

   # create relative path
   $_ = $dirname; $replacevardir = $var{'dirmfiles'};
   s/$replacevardir//; $relpath = $_;
   s/[^\/]+/../g; $relpathtoindex = $_;

   # producetree no
   if ($var{'producetree'} eq 'no') { $relpath = ''; $relpathtoindex = ''; }

   # names of directories (top-level and below top-level m-file-directory)
   push(@directories, $dirname);
   $dirnumbermfiles{$dirname} = 0;    # set number of m-files for this dir to zero
   # relative path from top-level directory, depends on directory name
   $dirnamerelpath{$dirname} = $relpath;
   # relative path from actual directory to top-level directory, depends on directory name
   $dirnamerelpathtoindex{$dirname} = $relpathtoindex;
   # recursion level for directory, depends on directory name
   $dirnamerecdeep{$dirname} = $localRecDeep;
   
   # only the name of the directory, without path
   $rindexprint = rindex($dirname, $dirsep, length($dirname)-2);
   $rindsub = substr($dirname, $rindexprint+1, length($dirname)-$rindexprint-2);
   $dirnamesingle{$dirname} = $rindsub;

   # create name of html-directories 
   $_ = $dirname;
   s/$var{'dirmfiles'}/$var{'dirhtml'}/;
   $dirhtmlname = $_;
   if ($var{'producetree'} eq 'no') { $dirhtmlname = $var{'dirhtml'}; }
   # try to open html directory, if error, then create directory,
   # use same mode as for corresponding m-file directory
   opendir(CHECKDIR,"$dirhtmlname") || do {
      $dirmode = (stat($dirname))[2]; # print "$dirmode\n";
      mkdir("$dirhtmlname", $dirmode) || die ("Cannot create directory $dirhtmlname: $! !");
   };
   closedir(CHECKDIR);


   # read everything from this directory and process them
   @ALLEFILES = readdir(AKTDIR);

   foreach $file (@ALLEFILES) {
      # exclude . and .. directories
      next if $file eq '.';  next if $file eq '..';

      # test for existense of entry (redundant, used for debugging)
      if (-e $dirname.$file) {
         # if it's a directory, call this function recursively
         if (-d $dirname.$file) {
            if ($var{'processtree'} eq 'yes') {
               &ParseTreeReadFiles($dirname.$file.$dirsep, $localRecDeep+1);
            }
         }
         # if it's a file - test for m-file, save name and create some arrays
         elsif (-f $dirname.$file) {
            if ($file =~ /\.$suffixforsearch$/i) {
               # Remove the file suffix to establish the matlab identifiers
               $filewosuffix = $file;
               $filewosuffix =~ s/\.$suffixforsearch$//i;
               # $filename = $name;

               # Contents file in unix must start with a capital letter (Contents.m)
               # ensure, that m-file name is lower case, except the contents file
               if (! ($filewosuffix =~ /^contents$/i)) {
                  # if ($var{'links2filescase'}  eq 'low') { $filewosuffix = "\L$filewosuffix\E"; }
                  $filewosuffixlow = "\L$filewosuffix\E";
               }
               else { $contentsname{$dirname} = $filewosuffix; }

               # internal handle name is always lower case
               $name     = $filewosuffixlow;
               # file name is not lower case
               $filename = $filewosuffix;

               # if don't use C|contents.m, then forget all C|contents.m
               if ($var{'usecontentsm'} eq 'no') { if ($name =~ /contents/i) { next; } }

               # if m-file with this name already exists, use directory and name for name
               # only the first occurence of name will be used for links
               if (defined $mfile{$name}) { 
                  if (! ($name =~ /^contents$/i) ) {
                     print "\r ParseTree - Name conflict:  $name in $dirname already exists: $mfile{$name} !\n";
                     print   "             $mfile{$name}  will be used for links!\n";
                  }
                  $name = $dirname.$name;
               }
               # mfile name with path
               $mfile{$name} = $dirname.$file;
               # mfile name (without path)
               $mfilename{$name} = $filename;
               # mfile directory
               $mfiledir{$name} = $dirname;
               
               # html file name and full path, special extension of Contents files
               if ($name =~ /contents/i) { $extrahtmlfilename = $dirnamesingle{$dirname}; }
               else { $extrahtmlfilename = ''; }
               $hfile{$name} = $dirhtmlname.$mfilename{$name}.$extrahtmlfilename.$var{'exthtml'};

               # save relative html path
               # if ($var{'producetree'} eq 'yes') {
               $hfilerelpath{$name} = $relpath;
               # } else { # if no tree to produce, relative path is empty
               #    $hfilerelpath{$name} = '';
               # }

               # create relative path from html file to directory with global index file
               $hfileindexpath{$name} = $relpathtoindex;

               # Function declaration, if one exists, set default to script
               $synopsis{$name} = "";
               $mtype{$name} = "script";

               # First comment line
               $apropos{$name} = "";

               # count number of m-files in directories
               $dirnumbermfiles{$dirname}++;

               if ($debug > 1) {
                  if ($opt_silent) { print "\r"; }
                  print "   ParseTree: $name \t\t $mfile{$name} \t\t $hfile{$name}\t\t";
                  if (!$opt_silent) { print "\n"; }
               }
            }
         }
         else {
            print "Unknown type of file in $dirname: $file\n";
         }
      }
      else { print "Error: Not existing file in $dirname: $file\n"; }
   }

   closedir(AKTDIR)
   
}

#------------------------------------------------------------------------
# Construct Dependency matrix
#    $dep{$x,$y} > 0 if $x includes a reference to $y.
#------------------------------------------------------------------------
sub ConstructDependencyMatrix
{
   &ConstructDependencyMatrixReadFiles('all');
   &ConstructDependencyMatrixReally;
}


#------------------------------------------------------------------------
# Construct Dependency matrix
#    $dep{$x,$y} > 0 if $x includes a reference to $y.
#------------------------------------------------------------------------
sub ConstructDependencyMatrixReadFiles
{
   local($whatstring) = @_;
   local(*MFILE);
   local($name, $inames);
   local(%symbolsdep, %symbolsall);

   # Initialize as all zeros.
   # foreach $name (@names) { grep($dep{$name,$_}=0,@names); if ($debug > 0) { print "\r   DepMatrix anlegen: $name\t$#names\t"; } }

   # Compute the dependency matrix
   $inames = -1;
   foreach $name (@names) {
      # Read each file and tabulate the distinct alphanumeric identifiers in
      # an array of symbols. Also scan for:
      #   synopsis: The function declaration line
      #   apropos:  The first line of the help text

      # look for whatstring, if all: process every file, if contents: process only contents files 
      if ($whatstring eq 'contents') { if (! ($name =~ /contents$/i) ) { next; } }
      elsif ($whatstring eq 'all') { }    # do nothing
      else { print "\r   ConstructDependency: Unknown parameter whatstring: $whatstring \n"; }

      undef %symbolsall; undef %symbolsdep;
      open(MFILE,"<$mfile{$name}") || die("Can't open $mfile{$name}: $!\n");
      while (<MFILE>) {
         chop;

         # Split on nonalphanumerics, then look for all words, used for links later
         # this one for all references
         @wordsall = grep(/[a-zA-Z]\w*/, split('\W',$_));
         # set all words to lower case for link checking
         undef @wordsall2;
         # do case conversion not, case checking is done later
         foreach (@wordsall) { push(@wordsall2, "\L$_\E"); }
         # @wordsall2 = @wordsall;
         grep($symbolsall{$_}++, @wordsall2);

         # Store first comment line, skip all others.
         if (/^\s*%/) {
            if (!$apropos{$name}) {
               s/^\s*%\s*//;   # remove % and leading white spaces on line
               $_ = &SubstituteHTMLEntities($_);
               $apropos{$name} = $_;
            }
            next;
         }

         # If it's the function declaration line, then store it and skip
         # but only, when first function definition (multiple function lines when private subfunctions in file
         if ($synopsis{$name} eq '') {
            if (/^\s*function/) {
               s/^\s*function\s*//;
               $synopsis{$name} = $_;
               $mtype{$name} = "function";
               next;
            }
         }

         # Split off any trailing comments
         if ($_ ne '') {
            # this one for references in program code only
            # when syntax parsing, here is a working place
            ($statement) = split('%',$_,1);
            @wordsdep = grep(/[a-zA-Z]\w*/,split('\W',$statement));
            # do case conversion not, case checking is done later
            undef @wordsdep2;
            foreach (@wordsdep) { push(@wordsdep2, "\L$_\E"); }
            grep($symbolsdep{$_}++, @wordsdep2);
         }
      }
      close MFILE;

      # compute intersection between %symbolsall and @linknames
      delete($symbolsall{$name});
      # foreach $localsumall ($symbolsall) {
      #    $localsumall = "\L$localsumall\E";
      # }
      @{'all'.$name} = grep($symbolsall{$_}, @linknames);

      # compute intersection between %symbolsdep and @linknames
      delete($symbolsdep{$name});
      @{'depcalls'.$name} = grep($symbolsdep{$_}, @linknames);

      $inames++; print "\r   DepCallsMatrix: $inames/$#names\t $name\t";
      if ($debug > 2) { print "\n      depnames: @{'depcalls'.$name}\n      all: @{'all'.$name}\n"; } 
   }
}


#------------------------------------------------------------------------
# Construct Dependency matrix
#    $dep{$x,$y} > 0 if $x includes a reference to $y.
#------------------------------------------------------------------------
sub ConstructDependencyMatrixReally
{
   local($inames, $name);

   $inames = -1;
   foreach $name (@names) { undef %{'depint'.$name}; }
   foreach $name (@names) {
      grep(${'depint'.$_}{$name}++, @{'depcalls'.$name});
      $inames++; print "\r   DepCalledMatrix1: $inames/$#names\t $name\t";
   }
   $inames = -1;
   foreach $name (@names) {
      # compute intersection between %depint.name{$_} and @linknames
      if (defined (%{'depint'.$name})) { @{'depcalled'.$name} = grep(${'depint'.$name}{$_}, @linknames); }
      $inames++; print "\r   DepCalledMatrix2: $inames/$#names\t $name\t";
      if ($debug > 2) { print "\n      depcalled: @{'depcalled'.$name}\n"; }
   }

}


#========================================================================
# Construct all index files
#========================================================================
sub ConstructAllIndexFiles
{
   local(@localnames);
   local($ActDir);
   local($name);
   
   # define variables and names for frame target
   $GlobalNameFrameMainLeft = 'Cont_Main';
   $GlobalNameFrameMainRight = 'Cont_Lower';
   $GlobalNameFrameAZIndexsmall = 'IndexAZindex';
   $GlobalNameFrameAZIndexjump = 'IndexAZjump';

   $indexcreated = 0;

   &ConstructHighestIndexFile;
   $indexcreated++;

   # if ($var{'producetree'} eq 'yes') {
      # moved next 2 lines out of if for producetree no
      # &ConstructHighestIndexFile;
      # $indexcreated++;
   
      foreach $ActDir (@directories) {
         undef @localnames;
         foreach $name (@names) {
            local($pathsubstr) = substr($mfile{$name}, 0, rindex($mfile{$name}, "/")+1);
            if ($ActDir eq $pathsubstr) {
               if ($debug > 1) { print "IndexFile: $pathsubstr    ActDir: $ActDir   Hfilerelpath: $hfilerelpath{$name}\n"; }
               push(@localnames, $name);
            }
         }
         if ($debug > 2) { print "localnames: @localnames\n"; }
         # create contents file and short|long index of files in local directory
         &ConstructContentsmFile($ActDir, @localnames);
         &ConstructAZIndexFile($ActDir, 'short', 'local', @localnames);
         &ConstructAZIndexFile($ActDir, 'long', 'local', @localnames);
         $indexcreated+=2;
      }   
   # } else {
   #    &ConstructContentsmFile($var{'dirmfiles'}, @names);
   # }

   # create short|long index of files in all directory
   &ConstructAZIndexFile($var{'dirmfiles'}, 'short', 'global', @names);
   &ConstructAZIndexFile($var{'dirmfiles'}, 'long', 'global', @names);
   $indexcreated+=2;

   # if contents.m were created or updated, the dependency matrices should 
   # be updated as well
   if ($var{'writecontentsm'} eq 'yes') { &ConstructDependencyMatrixReadFiles('contents');; }
}


#========================================================================
# Construct the highest level index file
#========================================================================
sub ConstructHighestIndexFile
{
   local(*IFILE);
   local($indexfile, $filename);

   # Build the frame layout file, this files includes the layout of the frames
   # Build the frame layout file name (highest one)
   $indexfile = $var{'dirhtml'}.$var{'filenametopframe'}.$var{'exthtml'};

   if ($var{'frames'} eq 'yes') {

       open(IFILE,">$indexfile") || die("Cannot open frame layout file $indexfile\n");

       # Write the header of frame file
       print IFILE "$TextDocTypeFrame\n<html>\n<head>\n$var{'codeheadmeta'}\n$TextMetaCharset\n";
       print IFILE "   <title>$var{'texttitleframelayout'}</title>\n";
       print IFILE "</head>\n";

       # definition of 2 frames, left the tree of directories,
       # right the index of that directory or the docu of a file
       print IFILE "<frameset  cols=\"25%,75%\">\n";
       print IFILE "   <frame src=\"$var{'filenamedirshort'}$var{'exthtml'}\" name=\"$GlobalNameFrameMainLeft\" />\n";
       print IFILE "   <frame src=\"$var{'filenameindexshortglobal'}$var{'filenameextensionframe'}$var{'exthtml'}\" name=\"$GlobalNameFrameMainRight\" />\n";   print IFILE "</frameset>\n";

       print IFILE "</html>\n";

       close(IFILE);

       if ($opt_silent) { print "\r"; }
       print "   Frame layout file created: $indexfile\t";
       if (!$opt_silent) { print "\n"; }
   }

   for($irun=0; $irun <= 2; $irun++) {
      # Build the top directory index file, these files include the directory tree
      # Build the directory tree index file name
      
      # Create no directory file for contents, when no contents to use
      if (($irun == 2) && ($var{'usecontentsm'} eq 'no')) { next; }

      # Assign the correct index file name
      if ($irun == 0) { $filename = $var{'filenamedirshort'}; }
      elsif ($irun == 1) { $filename = $var{'filenamedirlong'}; }
      elsif ($irun == 2) { $filename = $var{'filenamedircontents'}; }
      
      $indexfile = $var{'dirhtml'}.$filename.$var{'exthtml'};

      open(IFILE,">$indexfile") || die("Cannot open directory tree index file $indexfile\n");
      # Write header of HTML file
      print IFILE "$TextDocTypeHTML\n<html>\n<head>\n$var{'codeheadmeta'}\n$TextMetaCharset\n$var{'csslink'}\n";

      if ($var{'texttitleindexalldirs'} eq '') {
         print IFILE "<title>Index of Directories of $var{'dirmfiles'}</title>\n";
      } else {
         print IFILE "<title>$var{'texttitleindexalldirs'}</title>\n";
      }
      
      if ($var{'frames'} eq 'yes') {
	  print IFILE "<base target=\"$GlobalNameFrameMainRight\" />\n";
      }

      print IFILE "</head>\n";
      print IFILE "<body $var{'codebodyindex'}>\n";
      if ($var{'textheaderindexalldirs'} eq '') {
         print IFILE "<h1 $var{'codeheader'}>Index of Directories of <em>$var{'dirmfiles'}</em></h1>\n";
      } else {
         print IFILE "<h1 $var{'codeheader'}>$var{'textheaderindexalldirs'}</h1>\n";
      }
      print IFILE "<p align=\"center\">\n";

      if ($var{'frames'} eq 'yes') {
	  if ($irun == 0) { print IFILE "<strong>short</strong>\n"; }
	  else { print IFILE "<a href=\"$var{'filenamedirshort'}$var{'exthtml'}\" target=\"$GlobalNameFrameMainLeft\">short</a>\n"; }
	  if ($irun == 1) { print IFILE " | <strong>long</strong>\n"; }
	  else { print IFILE " | <a href=\"$var{'filenamedirlong'}$var{'exthtml'}\" target=\"$GlobalNameFrameMainLeft\">long</a>\n"; }
	  if ($var{'usecontentsm'} eq 'yes') {
	      if ($irun == 2) { print IFILE " | <strong>contents</strong>\n"; }
	      else { print IFILE " | <a href=\"$var{'filenamedircontents'}$var{'exthtml'}\" target=\"$GlobalNameFrameMainLeft\">contents</a>\n"; }
	  }
      } else {
	  if ($irun == 0) { print IFILE "<strong>short</strong>\n"; }
	  else { print IFILE "<a href=\"$var{'filenamedirshort'}$var{'exthtml'}\">short</a>\n"; }
	  if ($irun == 1) { print IFILE " | <strong>long</strong>\n"; }
	  else { print IFILE " | <a href=\"$var{'filenamedirlong'}$var{'exthtml'}\">long</a>\n"; }
	  if ($var{'usecontentsm'} eq 'yes') {
	      if ($irun == 2) { print IFILE " | <strong>contents</strong>\n"; }
	      else { print IFILE " | <a href=\"$var{'filenamedircontents'}$var{'exthtml'}\">contents</a>\n"; }
	  }
      }
   
      print IFILE "</p><br />\n\n";
      print IFILE "<ul>\n";

      # go through all directories and create a list entry for each one,
      # depending on recursion level create sublists
      $prevrecdeeplevel = 0;
      foreach $name (@alldirectories) {
         $actrecdeeplevel = $dirnamerecdeep{$name};
         for( ; $prevrecdeeplevel < $actrecdeeplevel; $prevrecdeeplevel++ ) { print IFILE "<ul>\n"; }
         for( ; $prevrecdeeplevel > $actrecdeeplevel; $prevrecdeeplevel-- ) { print IFILE "</ul>\n"; }
         if ($irun == 0) { $indexfilenameused = $var{'filenameindexshortlocal'}.$var{'filenameextensionframe'}; }
         elsif ($irun == 1) { $indexfilenameused = $var{'filenameindexlonglocal'}.$var{'filenameextensionframe'}; }
         elsif ($irun == 2) { $indexfilenameused = $contentsname{$name}; }
         else { die "ConstructHighestIndexFile: Unknown value of irun"; }
         if ($dirnumbermfiles{$name} > 0) {
            # producetree no
            # if ($var{'producetree'} eq 'no') { $dirnamehere = ''; }
            # else { $dirnamehere = '$dirnamerelpath{$name}'; }
            # print IFILE "<LI><A HREF=\"$dirnamehere$indexfilenameused_$dirnamesingle{$name}$var{'exthtml'}\">$dirnamesingle{$name}</A>\n";
            print IFILE "<li><a href=\"$dirnamerelpath{$name}$indexfilenameused$dirnamesingle{$name}$var{'exthtml'}\">$dirnamesingle{$name}</a></li>\n";
         } else { 
            # print directories with no m-files inside not
            # print IFILE "<li>$dirnamesingle{$name}</li>\n";
         }
      }
      $actrecdeeplevel = 0;
      for( ; $prevrecdeeplevel > $actrecdeeplevel; $prevrecdeeplevel-- ) { print IFILE "</ul>\n"; }
      print IFILE "</ul>\n<br />$var{'codehr'}\n";

      # Include info about author from authorfile
      &WriteFile2Handle($var{'authorfile'}, IFILE);

      print IFILE "<!--navigate-->\n";
      print IFILE "<!--copyright-->\n";
      print IFILE "</body>\n</html>\n";

      close(IFILE);

      if ($opt_silent) { print "\r"; }
      print "   Directory - Indexfile created: $indexfile\t";
      if (!$opt_silent) { print "\n"; }
   }
}


#========================================================================
# Construct the A-Z index file (global/local and/or short/long)
#========================================================================
sub ConstructAZIndexFile
{
   local($LocalActDir, $LocalShortLong, $LocalGlobalLocal, @localnames) = @_;
   local(*IFILE);
   local($name, $indexfilename, $dirpath);
   local($firstletter, $firstone);
   
   if ($debug > 2) { print "localnames in AZ small: @localnames\n"; print "     ActDir in A-Z: $LocalActDir\n"; }
   
   # extract filename of index file from parameters of function
   if ($LocalShortLong eq 'short') {
      if ($LocalGlobalLocal eq 'global') { $indexfilename = $var{'filenameindexshortglobal'}; }
      elsif ($LocalGlobalLocal eq 'local') { $indexfilename = $var{'filenameindexshortlocal'}; }
      else { die "wrong parameter for LocalGlobalLocal in ConstructAZIndexFile: $LocalGlobalLocal."; }
   } elsif ($LocalShortLong eq 'long') {
      if ($LocalGlobalLocal eq 'global') { $indexfilename = $var{'filenameindexlongglobal'}; }
      elsif ($LocalGlobalLocal eq 'local') { $indexfilename = $var{'filenameindexlonglocal'}; }
      else { die "wrong parameter for LocalGlobalLocal in ConstructAZIndexFile: $LocalGlobalLocal."; }
   } else { die "wrong parameter for LocalShortLong in ConstructAZIndexFile: $LocalShortLong."; }
   
   # producetree no
   # if ($var{'producetree'} eq 'no') { $dirnamehere = ''; }
   # else { $dirnamehere = '$dirnamerelpath{$LocalActDir}'; }
   # Build the index file name
   # handle the global index file case separately (no extra directory name in file)
   #    the local index file name must be extended by the name of the directory
   if ($LocalGlobalLocal eq 'global') { $extradirfilename = ''; }
   else { $extradirfilename = $dirnamesingle{$LocalActDir}; }
   $indexfile = $var{'dirhtml'}.$dirnamerelpath{$LocalActDir}.$indexfilename.$var{'filenameextensionindex'}.$extradirfilename.$var{'exthtml'};

   if ($LocalShortLong eq 'short' and $var{'frames'} ne 'yes') {
       # With no frames, this must go in the top-level index file instead
       $indexfile = $var{'dirhtml'}.$var{'filenametopframe'}.$var{'exthtml'};
   }

   if ($debug > 2) { print "   indexfilename (a-z small): $indexfile\n"; }

   open(IFILE,">$indexfile") || die("Cannot open index file $indexfile: $!\n");

   # Write the header of HTML file
   print IFILE "$TextDocTypeHTML\n<html>\n<head>\n$var{'codeheadmeta'}\n$TextMetaCharset\n$var{'csslink'}\n";
   
   if ($var{'texttitleindex'} eq '') {
      print IFILE "<title>Index of Matlab Files in Directory $LocalActDir</title>\n";
   } else {
      if ($LocalGlobalLocal eq 'global') { print IFILE "<title>$var{'texttitleindex'}</title>\n"; }
      else { print IFILE "<title>$var{'texttitleindex'} in Directory $LocalActDir</title>\n"; }
   }

   if ($var{'frames'} eq 'yes') {
       print IFILE "<base target=\"$GlobalNameFrameMainRight\" />\n";
   }
   print IFILE "</head>\n";

   print IFILE "<body $var{'codebodyindex'}>\n";
   if ($var{'textheaderindex'} eq '') {
      print IFILE "<h1 $var{'codeheader'}>Index of Matlab Files in Directory $LocalActDir</h1>\n";
   } else {
      if ($LocalGlobalLocal eq 'global') { print IFILE "<h1 $var{'codeheader'}>$var{'textheaderindex'}</h1>\n"; }
      else { print IFILE "<h1 $var{'codeheader'}>$var{'textheaderindex'} in Directory $LocalActDir</h1>\n"; }
   }

   # include links to indexes
   &ConstructLinks2Index(IFILE, $dirnamerelpathtoindex{$LocalActDir}, $LocalActDir, $LocalGlobalLocal);

   # Collect the starting letters of m files in this directory or all m-files
   for('a'..'z') { undef @{$_}; }
   foreach $name (@localnames) {
      if (! ($mfilename{$name} =~ /contents/i)) {
         $firstletter = substr($mfilename{$name}, 0, 1);
         # convert first letter always to lower case
         # needed for reference to lower and upper case m-files
         $firstletter = "\L$firstletter\E";
         push(@{$firstletter}, $name);
      }
   }
   
   if ($LocalShortLong eq 'short') {
      # begin create short index
      print IFILE "<table width=\"100%\">\n";

      for('a'..'z') {
         # print "   $_: @{$_}\n";
         $numberofletter = $#{$_}+1;
         if ($numberofletter > 0) {
            print IFILE "\n<tr><td colspan=\"2\"><br /><strong><a name=\"\U$_\E$_\" class=\"an\">\U$_\E</a></strong></td></tr>\n";
            $numberhalf = ($numberofletter + 1 - (($numberofletter+1) % 2))/2;
            if ($debug > 2) { print "   $_: @{$_} \t $numberhalf \t $numberofletter\n"; }
            for($count = 0; $count < $numberhalf; $count++) {
               $name = @{$_}[$count];
               if ($LocalGlobalLocal eq 'global') { $dirpath = $hfilerelpath{$name}; } else { $dirpath = ""; }
               print IFILE "<tr><td width=\"50%\"><a href=\"$dirpath$mfilename{$name}$var{'exthtml'}\">$mfilename{$name}</a></td>";
               if (($count + $numberhalf) < $numberofletter) {
                  $name = @{$_}[$count + $numberhalf];
                  if ($LocalGlobalLocal eq 'global') { $dirpath = $hfilerelpath{$name}; } else { $dirpath = ""; }
                  print IFILE "<td width=\"50%\"><a href=\"$dirpath$mfilename{$name}$var{'exthtml'}\">$mfilename{$name}</a></td></tr>\n";
               } else {
                  print IFILE "<td width=\"50%\"></td></tr>\n";
               }
            }
         }
      }
      print IFILE "</table>\n<br />$var{'codehr'}\n";

   } elsif ($LocalShortLong eq 'long') {
      # begin create long index
      print IFILE "<table border=\"5\" width=\"100%\" cellpadding=\"5\">\n";
      print IFILE "<tr align=\"center\"><th>Name</th><th>Description</th></tr>\n";

      for('a'..'z') {
         # print "   $_: @{$_}\n";
         $numberofletter = $#{$_}+1;
         if ($numberofletter > 0) {
            $firstone = 1;
            foreach $name (@{$_}) {
               if ($debug > 1) { print "   AZinforeach1: $name \t\t $hfilerelpath{$name} \t\t $dirnamerelpath{$LocalActDir}\n"; }
               if ($LocalGlobalLocal eq 'global') { $dirpath = $hfilerelpath{$name}; } else { $dirpath = ""; }
               if (! ($mfilename{$name} =~ /contents/i)) {
                  if ($firstone == 1) { print IFILE "\n<tr><td colspan=\"2\"><br /><strong><a name=\"\U$_\E$_\" class=\"an\">\U$_\E</a></strong></td></tr>\n"; $firstone = 0; } 
                  print IFILE "<tr><td valign=\"top\"><a href=\"$dirpath$mfilename{$name}$var{'exthtml'}\">$mfilename{$name}</a></td><td>$apropos{$name}</td></tr>\n";
               }
            }
         }
      }
      print IFILE "</table>\n<br />$var{'codehr'}\n";
   } else { die "wrong parameter for LocalShortLong in ConstructAZIndexFile: $LocalShortLong."; }

   # Include info about author from authorfile
   &WriteFile2Handle($var{'authorfile'}, IFILE);

   print IFILE "<!--navigate-->\n";
   print IFILE "<!--copyright-->\n";
   print IFILE "</body>\n</html>\n";

   close(IFILE);

   if ($opt_silent) { print "\r"; }
   print "   Indexfile small (A-Z) created: $indexfile\t";
   if (!$opt_silent) { print "\n"; }


   # Build the A-Z jump index file name
   # handle the global index file case separately (no extra directory name in file)
   if ($LocalGlobalLocal eq 'global') { $extradirfilename = ''; }
   else { $extradirfilename = $dirnamesingle{$LocalActDir}; }

   if ($var{'frames'} eq 'yes') {

       $indexfile = $var{'dirhtml'}.$dirnamerelpath{$LocalActDir}.$indexfilename.$var{'filenameextensionjump'}.$extradirfilename.$var{'exthtml'};
       if ($debug > 2) { print "   indexfilename (a-z jump): $indexfile\n"; }
       open(IFILE,">$indexfile") || die("Cannot open jump index file $indexfile: $!\n");

       # Write the header of HTML file
       print IFILE "$TextDocTypeHTML\n<html>\n<head>\n$var{'codeheadmeta'}\n$TextMetaCharset\n$var{'csslink'}\n";
       
       if ($var{'texttitleindex'} eq '') {
	   print IFILE "<title>A-Z jump index in directory $LocalActDir</title>\n";
       } else {
	   if ($LocalGlobalLocal eq 'global') { print IFILE "<title>$var{'texttitleindex'}</title>\n"; }
	   else { print IFILE "<title>$var{'texttitleindex'} in Directory $LocalActDir</title>\n"; }
       }

       if ($var{'frames'} eq 'yes') {
	   print IFILE "<base target=\"$GlobalNameFrameAZIndexsmall\" />\n";
       }
       print IFILE "</head>\n";
       print IFILE "<body $var{'codebodyindex'}>\n";

       # Write the A-Z jump line, generate link for letters with files starting with this letter
       # and only letters for no files starting with this letter
       # use previously generated arrays with names of files sorted by starting letter
       for('a'..'z') {
	   $numberofletter = $#{$_}+1;
	   if ($numberofletter > 0) {
	       print IFILE "<strong><a href=\"$indexfilename$var{'filenameextensionindex'}$extradirfilename$var{'exthtml'}#\U$_\E$_\">\U$_\E</a> </strong>\n";
	   } else {
	       print IFILE "\U$_\E \n";
	   }
       }

       print IFILE "</body>\n</html>\n";

       close(IFILE);

       if ($opt_silent) { print "\r"; }
       print "   Indexfile small (A-Z jump) created: $indexfile\t";
       if (!$opt_silent) { print "\n"; }
   }


   # Build the frame layout file, this file includes the layout of the frames
   # Build the frame layout file name (for small/compact A-Z index)
   # handle the global index file case separately (no extra directory name in file)
   if ($LocalGlobalLocal eq 'global') { $extradirfilename = ''; }
   else { $extradirfilename = $dirnamesingle{$LocalActDir}; }

   if ($var{'frames'} eq 'yes') {

       $indexfile = $var{'dirhtml'}.$dirnamerelpath{$LocalActDir}.$indexfilename.$var{'filenameextensionframe'}.$extradirfilename.$var{'exthtml'};
       if ($debug > 2) { print "   indexfilename (a-z frame): $indexfile\n"; }

       open(IFILE,">$indexfile") || die("Cannot open jump index frame file $indexfile: $!\n");

       # Write the header of Frame file
       print IFILE "$TextDocTypeHTML\n<html>\n<head>\n$var{'codeheadmeta'}\n$TextMetaCharset\n$var{'csslink'}\n";

       if ($var{'texttitleindex'} eq '') {
	   print IFILE "<title>Index of Matlab Files in Directory $LocalActDir</title>\n";
       } else {
	   if ($LocalGlobalLocal eq 'global') { print IFILE "<title>$var{'texttitleindex'}</title>\n"; }
	   else { print IFILE "<title>$var{'texttitleindex'} in Directory $LocalActDir</title>\n"; }
       }
       print IFILE "</head>\n";

       # definition of 2 frames, top the A-Z index, below the jump letter line
       print IFILE "<frameset  rows=\"90%,10%\">\n";
       print IFILE "   <frame src=\"$indexfilename$var{'filenameextensionindex'}$extradirfilename$var{'exthtml'}\" name=\"$GlobalNameFrameAZIndexsmall\" />\n";
       print IFILE "   <frame src=\"$indexfilename$var{'filenameextensionjump'}$extradirfilename$var{'exthtml'}\" name=\"$GlobalNameFrameAZIndexjump\" />\n";
       print IFILE "</frameset>\n";

       print IFILE "</html>\n";

       close(IFILE);

       if ($opt_silent) { print "\r"; }
       print "   Frame layout file created: $indexfile\t";
       if (!$opt_silent) { print "\n"; }
   }
}
   

#========================================================================
# Construct the links to all indexes
#========================================================================
sub ConstructLinks2Index
{
   local(*WRITEFILE, $LocalPath2Index, $PathContents, $LocalGlobalLocal) = @_;
   
   # include links to short/long - local/global index and C|contents.m
   print WRITEFILE "\n<p align=\"center\">";
   print WRITEFILE "$var{'textjumpindexglobal'} (";

   if ($var{'frames'} eq 'yes') {
       print WRITEFILE "<a href=\"$LocalPath2Index$var{'filenameindexshortglobal'}$var{'filenameextensionframe'}$var{'exthtml'}\">short</a> | ";
   } else {
       print WRITEFILE "<a href=\"$LocalPath2Index$var{'filenametopframe'}.$var{'exthtml'}\">short</a> | ";
   }

   print WRITEFILE "<a href=\"$LocalPath2Index$var{'filenameindexlongglobal'}$var{'filenameextensionframe'}$var{'exthtml'}\">long</a>)\n";
   if ($LocalGlobalLocal eq 'local') {
      if ($var{'usecontentsm'} eq 'yes') {
         print WRITEFILE " | <a href=\"$contentsname{$PathContents}$dirnamesingle{$PathContents}$var{'exthtml'}\">Local contents</a>\n";
      }
      # if ($var{'producetree'} eq 'yes') {
         print WRITEFILE " | $var{'textjumpindexlocal'} (";
         print WRITEFILE "<a href=\"$var{'filenameindexshortlocal'}$var{'filenameextensionframe'}$dirnamesingle{$PathContents}$var{'exthtml'}\">short</a> | ";
         print WRITEFILE "<a href=\"$var{'filenameindexlonglocal'}$var{'filenameextensionframe'}$dirnamesingle{$PathContents}$var{'exthtml'}\">long</a>)\n";
      # }
   }
   print WRITEFILE "</p>\n\n";
   print WRITEFILE "$var{'codehr'}\n";
}


#========================================================================
# Construct the contents.m files or update
#========================================================================
sub ConstructContentsmFile
{
   local($LocalActDir, @localnames) = @_;
   local(*CFILE, $name,$newline);
   local($contentsfile, $isincontentsonly);
   local(@lines, @autoaddlines, @emptylines);
   local($autoadd) = 'AutoAdd';
   local($autoaddsection) = 0;
   local($emptylineflag) = 0;
   local(%nameincontents);
   
   # Build the contents file name
   $contentsfile = $LocalActDir.$contentsname{$LocalActDir}.$suffix;
   
   if (-e $contentsfile) {
      open(CFILE,"<$contentsfile") || die("Cannot open contents file $contentsfile: $!\n");
      while (<CFILE>) {
         # Search for the specified string pattern
         @words = split;
         if ((@words >= 3) && ($words[2] eq '-')) {
            $isincontentsonly = 0;
            foreach $name (@localnames) {
               if ($name eq $words[1]) {    # old
               # if ($mfilename{$name} eq $words[1]) {
                  $isincontentsonly = 1;
                  $nameincontents{$name} = 1;
                  $newline = sprintf("%% %-13s - %s\n", $mfilename{$name}, $apropos{$name});
                  push(@lines, $newline);
               }
            }
            # issue a warning, if file is in contents, but not as file in the directory
            if ($isincontentsonly == 0) {
               print "\rConstructContents: Obsolete entry  $words[1]  in  $contentsfile ! Entry not used.\n";
            }
         } else {
            # look for the AutoAdd section, should be the second word
            if ((@words >= 2) && ($words[1] eq $autoadd)) { $autoaddsection = 1; }
            # push the red line in an array
            push(@lines, $_); 
         }
      }   
      close(CFILE);
   } else {
      $newline = "% MATLAB Files in directory  $LocalActDir\n%\n";
      push(@lines, $newline);
      
   }
   
   # collect the file names, that were not included in original C|contents.m
   foreach $name (@localnames) {
      if (! defined $nameincontents{$name}) {
         if (! ($mfilename{$name} =~ /contents/i)) {
            $newline = sprintf("%% %-13s - %s\n", $mfilename{$name}, $apropos{$name});
            push(@autoaddlines, $newline);
         }   
      }
   }

   # write/update C|contents.m only if variable is set
   if ($var{'writecontentsm'} eq 'yes') {
      unlink($contentsfile);
      open(CFILE,">$contentsfile") || die("Cannot open contents file $contentsfile: $!\n");
      # write old C|contents.m or header of new file, as long as comment lines
      foreach $line (@lines) {
         if ($emptylineflag == 0) {
            if ($line =~ /^\s*%/) { print CFILE $line; }
            else { $emptylineflag = 1; push(@emptylines, $line); }
         } else { push(@emptylines, $line); }
      }
      # add header of AutoAdd section
      if (($autoaddsection == 0) && (@autoaddlines > 0)) { print CFILE "%\n% $autoadd\n"; }
      # add autoadd section lines (previously undocumented files
      foreach $line (@autoaddlines) { print CFILE $line; }
      # add tail of original C|contents.m (everything behind first non-comment line)
      foreach $line (@emptylines)   { print CFILE $line; }
      print CFILE "\n";
      close CFILE;
      if ($opt_silent) { print "\r"; }
      print "   Contents file created/updated: $contentsfile\t";
      if (!$opt_silent) { print "\n"; }
   }
}


#========================================================================
# Replace found special characters with their HTMl Entities
#========================================================================
sub SubstituteHTMLEntities {
   local($_) = @_;
   
   # Replace & <-> &amp;  < <-> &lt;  > <-> &gt;  " <-> &quot;
   s/&/&amp;/g; s/\</&lt;/g; s/\>/&gt;/g; s/\"/&quot;/g;
   return $_;
}

#========================================================================
# Replace found m-filenamestring with full link.
#========================================================================
sub SubstituteName2Link {
   local($_, $funname) = @_;
   local($refstr1, $refstr2, $reffound);
   
   # Look for something matching in the line
   if ( /(\W+)($funname)(\W+)/i ) {
      $reffound = $2;
      $refstr1 = "<a class=\"mfun\" href=\"$hfileindexpath{$name}$hfilerelpath{$funname}$funname$var{'exthtml'}\">";
      $refstr2 = "<\/a>";
      # Do links only for exact case match
      if ( ($var{'links2filescase'}  eq 'exact') || ($var{'links2filescase'}  eq 'exactvery') ) {
         if ( /(\W+)($funname)(\W+)/g ) {
            s/(\W+)($funname)(\W+)/$1$refstr1$funname$refstr2$3/g;
         }
         else {
            # Print info for not matching case in references, good for check up of files
            if ( ($var{'links2filescase'}  eq 'exactvery') ) {
               print "Diff in case found: $funname  (case of file name)   <->  $reffound  (case in source code)\n";  
               print "     (source line)  $_ \n";
            }
         }
      }
      # Do links for exact match and additionally for all upper case (often used in original matlab help text)
      elsif ( ($var{'links2filescase'}  eq 'exactupper') ) {
         s/(\W+)($funname)(\W+)/$1$refstr1$2$refstr2$3/g;
         $funname2 = "\U$funname\E";
         s/(\W+)($funname2)(\W+)/$1$refstr1$2$refstr2$3/g;
      }
      # Do links for all case mixes, this calls for trouble under LINUX/UNIX
      else {  #elsif ( ($var{'links2filescase'}  eq 'all') )
         s/(\W+)($funname)(\W+)/$1$refstr1$2$refstr2$3/ig;
      }
   }
   
   return $_;
}

#========================================================================
# Construct the html files for each matlab file.
#    Need to reread each matlab file to find the help text.
#    Note that we can't do this in a single loop because sometimes
#    the help text maybe before the function declaration.
#========================================================================
sub ConstructHTMLFiles
{
   local(*MFILE);
   local(*HFILE);

   local($filescreated) = 0;
   local($functionline);
   
   foreach $name (@names) {
      # Create cross reference information already here, used for keywords as well
      # Construct list of referenced functions
      @xref = @{'depcalls'.$name};    # the functions, that this m-file calls
      @yref = @{'depcalled'.$name};   # the functions, that this m-file is called from
      # print "   depcalls: @{'depcalls'.$name}\n   depcalled: @{'depcalled'.$name}\n";
      # foreach $cname (@names) { next if $cname eq $name; push(@yref,$cname) if grep(/$name/,@{'depcalls'.$cname}); }


      # Open m-file and html-file
      open(MFILE,"<$mfile{$name}");
      open(HFILE,">$hfile{$name}");

      # Write the header of HTML file
      print HFILE "$TextDocTypeHTML\n<html>\n<head>\n$var{'codeheadmeta'}\n$TextMetaCharset\n$var{'csslink'}\n";

      # Write meta tags: use apropos (one line function description) for description
      # and cross reference function names for keywords (any better ideas?)
      print HFILE "<meta name=\"description\" content=\" $apropos{$name} \" />\n";
      print HFILE "<meta name=\"keywords\" content=\" @xref @yref \" />\n";

      # Write Title and start body of html-file
      print HFILE "<title>$var{'texttitlefiles'} $mfilename{$name}</title>\n</head>\n";
      print HFILE "<body $var{'codebodyfiles'}>\n";
      print HFILE "<h1 $var{'codeheader'}>$var{'textheaderfiles'} $mfilename{$name}</h1>\n";
      print HFILE "$var{'codehr'}\n";

      # include links to short/long - local/global index and C|contents.m
      &ConstructLinks2Index(HFILE, $hfileindexpath{$name}, $mfiledir{$name}, 'local');

      # If this is a function, then write out the first line as a synopsis
      if ($mtype{$name} eq "function") {
         print HFILE "<h2 $var{'codeheader'}>Function Synopsis</h2>\n";
         print HFILE "<pre>$synopsis{$name}</pre>\n$var{'codehr'}\n";
      }

      # Look for the matlab help text block
      $functionline = "\n";
      do {
         $_ = <MFILE>;
         # remember functionline, if before help text block
         if (/^\s*function/) { $functionline = $_; }
      } until (/^\s*%/ || eof);
      if (! (eof(MFILE))) {
         print HFILE "<h2 $var{'codeheader'}>Help text</h2>\n";
         print HFILE "<pre>\n";
         while (/^\s*%/) {
            # First remove leading % and white space, then Substitute special characlers
            s/^\s*%//;
            $_ = &SubstituteHTMLEntities($_);

            # check/create cross references
            foreach $funname (@{'all'.$name}) {
               if ($funname =~ /simulink/) { print "\n Simulink - Filename: $name;  scanname: $funname\n"; }
               next if $funname eq $name;
               $_ = &SubstituteName2Link($_, $funname);
            }
            print HFILE $_;
            if (! eof) { $_ = <MFILE>; }
         }
         print HFILE "</pre>\n$var{'codehr'}\n";
      }

      # Write the cross reference information
      if (@xref || @yref) {
         print HFILE "<h2 $var{'codeheader'}>Cross-Reference Information</H2>\n";
         print HFILE "<table border=\"0\" width=\"100%\">\n<tr align=\"left\">\n<th width=\"50%\">";
         if (@xref) {
            print HFILE "This $mtype{$name} calls";
         }
         print HFILE "</th>\n<th width=\"50%\">";
         if (@yref) {
            print HFILE "This $mtype{$name} is called by";
         }
         print HFILE "</th>\n</tr>\n<tr valign=\"top\"><td>";
         if (@xref) {
            print HFILE "\n<ul>\n";
            foreach $cname (sort @xref) {
               print HFILE "<li><a class=\"mfun\" href=\"$hfileindexpath{$name}$hfilerelpath{$cname}$mfilename{$cname}$var{'exthtml'}\">$mfilename{$cname}</a></li>\n";
            }
            print HFILE "</ul>\n";
         }
         print HFILE "</td><td>";
         if (@yref) {
            print HFILE "\n<ul>\n";
            foreach $cname (sort @yref) {
               print HFILE "<li><a class=\"mfun\" href=\"$hfileindexpath{$name}$hfilerelpath{$cname}$mfilename{$cname}$var{'exthtml'}\">$mfilename{$cname}</a></li>\n";
            }
            print HFILE "</ul>\n";
         }
         print HFILE "</td>\n</tr>\n</table>\n";
         print HFILE "$var{'codehr'}\n";
      }

      # Include source text if requested
      if (($var{'includesource'} eq 'yes') && (! ($mfilename{$name} =~ /^contents$/i))) {
         print HFILE "<h2 $var{'codeheader'}>Listing of $mtype{$name} $mfilename{$name}</h2>\n";
         seek(MFILE,0,0);
         print HFILE "<pre>\n";
         $IsStillHelp = 2;
         print HFILE $functionline;    # functionline from scanning of help
         while (<MFILE>) {
            if ($IsStillHelp == 2) {
               next     if (/^\s*$/);
               next     if (/^\s*function/);
               if (/^\s*%/) { $IsStillHelp = 1; next; }
            } elsif ($IsStillHelp == 1) {
               next     if (/^\s*%/);
               $IsStillHelp = 0;
            }
            
            # Substritute special characters
            $_ = &SubstituteHTMLEntities($_);
            
            # check for comment in line and format with css em
            s/(.*)%(.*)/$1<em class=\"mcom\">%$2<\/em>/;

            # check/create cross references
            foreach $funname (@{'all'.$name}) {
               next if $funname eq $name;
               $_ = &SubstituteName2Link($_, $funname);
            }
            print HFILE $_;
         }
         print HFILE "</pre>\n$var{'codehr'}\n";
      }

      # Include info about author from authorfile
      &WriteFile2Handle($var{'authorfile'}, HFILE)   ;

      print HFILE "<!--navigate-->\n";
      print HFILE "<!--copyright-->\n";
      print HFILE "</body>\n</html>\n";
      close(MFILE);
      close(HFILE);

      # Print name of finished file
      if ($opt_silent) { print "\r"; }
      print "   HTML-File created: $hfile{$name}\t";
      if (!$opt_silent) { print "\n"; }
      $filescreated++;
   }

   print "\n$PROGRAM: $indexcreated index and $filescreated files created.\n"; 
}

#========================================================================
# Function:	CheckFileName
# Purpose:	.
#========================================================================
sub CheckFileName {
   local($filename, $description) = @_;
   local(*CHECKFILE);
   
   open(CHECKFILE,"<$filename") || do {
      if ($description eq '') {$description = 'file';}
      # if (!$opt_silent) { print "Cannot open $description $filename: $!\n"; }
      print "Cannot open $description $filename: $!\n";
      return 1;
   };
   close(CHECKFILE);
   return 0;

}

#========================================================================
# Function:	CheckDirName
# Purpose:	.
#========================================================================
sub CheckDirName {
   local($dirname, $description) = @_;
   local(*CHECKDIR);
   
   opendir(CHECKDIR,"$dirname") || die ("Cannot open $description directory $dirname: $!\n");
   closedir(CHECKDIR);
}

#========================================================================
# Function:	WriteFile2Handle
# Purpose:	.
#========================================================================
sub WriteFile2Handle {
   local($filename, *WRITEFILE) = @_;
   local(*READFILE);
   
   if ($filename ne '') {
      open(READFILE,"<$filename");  
      @filecontents = <READFILE>;
      close(READFILE);
      print WRITEFILE "@filecontents\n";
      # if (!$opt_silent) {print "      Contents of $filename added\n"};
   }
}


#========================================================================
# Function:	GetConfigFile
# Purpose:	Read user's configuration file, if such exists.
#========================================================================
sub GetConfigFile
{
   local($filename) = @_;
   local(*CONFIG);
   local($value);

   if (&CheckFileName($filename, 'configuration file')) {
      # if (!$opt_silent) { print "   Proceeding using built-in defaults for configuration.\n"; }
      print "   Proceeding using built-in defaults for configuration.\n";
      return 0;
   };

   open(CONFIG,"< $filename");
   while (<CONFIG>) {
      s/#.*$//;
      next if /^\s*$/o;

      # match keyword: process one or more arguments
      # keyword set
      if (/^\s*set\s+(\S+)\s*=\s*(.*)/) {
         # setting a configuration variable
         if (defined $var{$1}) {
            $var{$1} = $2;
            if ($debug > 3) { print "$1:   $var{$1}\n"; }
         }
         else {
            print "$PROGRAM: unknown variable `$1' in configuration file\n"
         }
      } else {
         chop($_);
         print "$PROGRAM: unknown keyword in configuration file in line: `$_'\n"
      }
   }
   close CONFIG;
   1;
}


#------------------------------------------------------------------------
# DisplayHelp - display help text using -h or -help command-line switch
#------------------------------------------------------------------------
sub DisplayHelp
{
   $help=<<EofHelp;
   $PROGRAM v$VERSION - generate html documentation from Matlab m-files

   Usage: $PROGRAM [-h] [-c config_file] [-m|dirmfiles matlab_dir] [-d|dirhtml html_dir]
                   [-i yes|no] [-r yes|no] [-p yes|no] [-quiet|q] [-a authorfile]

   $PROGRAM is a perl script that reads each matlab .m file in a directory
   to produce a corresponding .html file of help documentation and cross
   reference information. An index file is written with links to all of 
   the html files produced. The options are:

      -quiet         or -q : be silent, no status information during generation
      -help          or -h : display this help message
      -todo          or -t : print the todo list for $PROGRAM
      -version       or -v : display version

      -configfile    or -c : name of configuration file (default to $var{'configfile'}).
      -dirmfiles     or -m : top level directory containing matlab files to generate html for;
                             default to actual directory.
      -dirhtml       or -d : top level directory for generated html files;
                             default to actual directory.

      -includesource or -i : Include matlab source in the html documentation [yes|no]
                             default to yes.
      -processtree   or -r : create docu for m-file directory and all subdirectories [yes|no];
                             default to yes.
      -producetree   or -p : create multi-level docu identical to directory structure
                             of m-files [yes|no]; default to yes.
      -writecontentsm or -w: update or write contents.m files into the matlab source
                             directories [yes|no]; default to no.

      -authorfile    or -a : name of file including author information, last element in html;
                             default to empty.
      
   The command line setting overwrite all other settings (built-in and configuration file).
   The configuration file settings overwrite the built-in settings (and not the command
   line settings).

   Typical usages are:
     $PROGRAM   
        (use default parameters from perl script, if configuration 
         file is found -> generation of docu, else display of help)

     $PROGRAM -dirmfiles matlab -dirhtml html
        (generate html documentation for all m-files in directory matlab,
         place html files in directory html, use built-in defaults for
         all other parameters, this way all m-files in the directory
         matlab and below are converted and the generated html-files are
         placed in the directory html and below producing the same 
         directory structure than below matlab)

     $PROGRAM -quiet
        (use built-in parameters from perl script, if configuration 
         file is found use these settings as well, do generation,
         no display except critical errors, status of conversion and result)
         
     $PROGRAM -m toolbox -dirhtml doc/html -r yes -p no
        (convert all m-files in directory toolbox and below and place
         the generated html files in directory doc/html, read all m-files
         recursively, however, the generated html files are placed in one
         directory)

     $PROGRAM -m toolbox -dirhtml doc/html -i no -r no
        (convert all m-files in directory toolbox and place
         the generated html files in directory doc/html, do not read m-files
         recursively, do not include source code in documentation)

EofHelp

   die "$help";
}

#------------------------------------------------------------------------
# DisplayTodo - display ToDo list using -t or -todo command-line switch
#------------------------------------------------------------------------
sub DisplayTodo
{
   $todo=<<EofToDo;
      $PROGRAM v$VERSION - ToDo list

       o	use more than one high level directory
       
       o	what should/could be done here???

EofToDo

   die "$todo";
}


#------------------------------------------------------------------------
# ListVariables - list all defined variables and their values
#------------------------------------------------------------------------
sub ListVariables
{
   local($value);
   
   if ($debug > 0) {
      print "List of all variables and their values\n";
      foreach (sort keys %var)
      {
         if ($var{$_} eq '') {
            $value = "empty";
         } else {
            $value = $var{$_};
         }
         print "   $_\n      $value\n";
      }
      print "\n\n";
   }
}


__END__
:endofperl
