#!/usr/bin/perl -w

# Read a Doxyfile and print it out again to stdout, with only
# whitelisted keys in it and with some keys set to pre-fixed values.
#
# Note that OUTPUT_DIRECTORY is not included; it should be added by
# the caller

use strict;

my $txt = join "", <>;
$txt =~ s/^\s*#.*$//gm;
$txt =~ s/\\\n//gs;
$txt =~ s/\r//g;
$txt =~ s/\n\s*\n/\n/gs;

my %fixed = (
    FULL_PATH_NAMES => "NO",
    SYMBOL_CACHE_SIZE => 2,
    EXCLUDE_SYMLINKS => "YES",
    GENERATE_HTML => "YES",
    PERL_PATH => "/usr/bin/perl",
    HAVE_DOT => "YES",
    HTML_OUTPUT => ".",
    HTML_DYNAMIC_SECTIONS => "NO",
    SEARCHENGINE => "NO",
    DOT_FONTNAME => "FreeMono",
    DOT_FONTSIZE => 10,
    DOT_FONTPATH => "/usr/share/fonts/truetype/freefont",
    DOT_IMAGE_FORMAT => "png",
    DOT_PATH => "/usr/bin/dot",
    DOT_TRANSPARENT => "YES",
);

my @safe = qw(
DOXYFILE_ENCODING      
PROJECT_NAME           
PROJECT_NUMBER         
CREATE_SUBDIRS         
OUTPUT_LANGUAGE        
BRIEF_MEMBER_DESC      
REPEAT_BRIEF           
ABBREVIATE_BRIEF       
ALWAYS_DETAILED_SEC    
INLINE_INHERITED_MEMB  
STRIP_FROM_PATH        
STRIP_FROM_INC_PATH    
JAVADOC_AUTOBRIEF      
QT_AUTOBRIEF           
MULTILINE_CPP_IS_BRIEF 
INHERIT_DOCS           
SEPARATE_MEMBER_PAGES  
TAB_SIZE               
ALIASES                
OPTIMIZE_OUTPUT_FOR_C  
OPTIMIZE_OUTPUT_JAVA   
OPTIMIZE_FOR_FORTRAN   
OPTIMIZE_OUTPUT_VHDL   
EXTENSION_MAPPING      
BUILTIN_STL_SUPPORT    
CPP_CLI_SUPPORT        
SIP_SUPPORT            
IDL_PROPERTY_SUPPORT   
DISTRIBUTE_GROUP_DOC   
SUBGROUPING            
TYPEDEF_HIDES_STRUCT   
EXTRACT_ALL            
EXTRACT_PRIVATE        
EXTRACT_STATIC         
EXTRACT_LOCAL_CLASSES  
EXTRACT_LOCAL_METHODS  
EXTRACT_ANON_NSPACES   
HIDE_UNDOC_MEMBERS     
HIDE_UNDOC_CLASSES     
HIDE_FRIEND_COMPOUNDS  
HIDE_IN_BODY_DOCS      
INTERNAL_DOCS          
HIDE_SCOPE_NAMES       
SHOW_INCLUDE_FILES     
FORCE_LOCAL_INCLUDES   
INLINE_INFO            
SORT_MEMBER_DOCS       
SORT_BRIEF_DOCS        
SORT_MEMBERS_CTORS_1ST 
SORT_GROUP_NAMES       
SORT_BY_SCOPE_NAME     
GENERATE_TODOLIST      
GENERATE_TESTLIST      
GENERATE_BUGLIST       
GENERATE_DEPRECATEDLIST
ENABLED_SECTIONS       
MAX_INITIALIZER_LINES  
SHOW_USED_FILES        
SHOW_DIRECTORIES       
SHOW_FILES             
SHOW_NAMESPACES        
QUIET                  
WARNINGS               
WARN_IF_UNDOCUMENTED   
WARN_IF_DOC_ERROR      
WARN_NO_PARAMDOC       
INPUT_ENCODING         
RECURSIVE              
EXCLUDE                
EXCLUDE_SYMLINKS       
EXCLUDE_PATTERNS       
EXCLUDE_SYMBOLS        
EXAMPLE_RECURSIVE      
SOURCE_BROWSER         
INLINE_SOURCES         
STRIP_CODE_COMMENTS    
REFERENCED_BY_RELATION 
REFERENCES_RELATION    
REFERENCES_LINK_SOURCE 
VERBATIM_HEADERS       
ALPHABETICAL_INDEX     
COLS_IN_ALPHA_INDEX    
IGNORE_PREFIX          
HTML_TIMESTAMP         
HTML_ALIGN_MEMBERS     
ENABLE_PREPROCESSING   
MACRO_EXPANSION        
EXPAND_ONLY_PREDEF     
SEARCH_INCLUDES        
PREDEFINED             
EXPAND_AS_DEFINED      
SKIP_FUNCTION_MACROS   
ALLEXTERNALS           
EXTERNAL_GROUPS        
CLASS_DIAGRAMS         
HIDE_UNDOC_RELATIONS   
CLASS_GRAPH            
COLLABORATION_GRAPH    
GROUP_GRAPHS           
UML_LOOK               
TEMPLATE_RELATIONS     
INCLUDE_GRAPH          
INCLUDED_BY_GRAPH      
CALL_GRAPH             
CALLER_GRAPH           
GRAPHICAL_HIERARCHY    
DIRECTORY_GRAPH        
DOT_GRAPH_MAX_NODES    
MAX_DOT_GRAPH_DEPTH    
DOT_MULTI_TARGETS      
DOT_CLEANUP            
);

my %safehash;
for my $sk (@safe) { $safehash{$sk} = 1; }

my @lines = split "\n", $txt;

my %settings;

sub is_safe {
    my $key = shift;
    defined $safehash{$key} and $safehash{$key} == 1;
}

sub has_file_path {
    # Returns true if the given key expects a file path as a value.
    # We only need to test keys that are safe; unsafe keys have been
    # rejected already.
    my $key = shift;
    $key eq "INPUT" or
	$key =~ /^OUTPUT_/ or
	$key =~ /_PATH$/ or
	$key =~ /_PATTERNS$/;
}

sub is_safe_file_path {
    my $value = shift;
    not $value =~ /^\// and not $value =~ /\.\./;
}

foreach my $line (@lines) {

    chomp $line;
    my ($key, $value) = split /\s*=\s*/, $line;

    next if !defined $key;

    if ($key =~ /^GENERATE_/ and not $key =~ /LIST$/) {
	print STDERR "NOTE: Setting $key explicitly to NO\n";
	$settings{$key} = "NO";
	next;
    }
	
    if (!is_safe($key)) {
	print STDERR "NOTE: Skipping non-whitelisted key $key\n";
	next;
    }

    if (has_file_path($key) and !is_safe_file_path($value)) {
	print STDERR "ERROR: Unsafe file path \"$value\" for key $key\n";
	exit 1;
    }

    $settings{$key} = $value;
}

foreach my $key (keys %fixed) {
    my $value = $fixed{$key};
    print STDERR "NOTE: Setting $key to fixed value $value\n";
    $settings{$key} = $value;
}

print join "\n", map { "$_ = $settings{$_}" } keys %settings;
print "\n";
