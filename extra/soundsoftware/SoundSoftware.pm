package Apache::Authn::SoundSoftware;

=head1 Apache::Authn::SoundSoftware

SoundSoftware - a mod_perl module for Apache authentication against a
Redmine database and optional LDAP implementing the access control
rules required for the SoundSoftware.ac.uk repository site.

=head1 SYNOPSIS

This module is closely based on the Redmine.pm authentication module
provided with Redmine.  It is intended to be used for authentication
in front of a repository service such as hgwebdir.

Requirements:

1. Clone/pull from repo for public project: Any user, no
authentication required

2. Clone/pull from repo for private project: Project members only

3. Push to repo for public project: "Permitted" users only (this
probably means project members who are also identified in the hgrc web
section for the repository and so will be approved by hgwebdir?)

4. Push to repo for private project: "Permitted" users only (as above)

5. Push to any repo that is tracking an external repo: Refused always

=head1 INSTALLATION

Debian/ubuntu:

  apt-get install libapache-dbi-perl libapache2-mod-perl2 \
    libdbd-mysql-perl libauthen-simple-ldap-perl libio-socket-ssl-perl

Note that LDAP support is hardcoded "on" in this script (it is
optional in the original Redmine.pm).

=head1 CONFIGURATION

   ## This module has to be in your perl path
   ## eg:  /usr/local/lib/site_perl/Apache/Authn/SoundSoftware.pm
   PerlLoadModule Apache::Authn::SoundSoftware

   # Example when using hgwebdir
   ScriptAlias / "/var/hg/hgwebdir.cgi/"

   <Location />
       AuthName "Mercurial"
       AuthType Basic
       Require valid-user
       PerlAccessHandler Apache::Authn::SoundSoftware::access_handler
       PerlAuthenHandler Apache::Authn::SoundSoftware::authen_handler
       SoundSoftwareDSN "DBI:mysql:database=redmine;host=localhost"
       SoundSoftwareDbUser "redmine"
       SoundSoftwareDbPass "password"
       Options +ExecCGI
       AddHandler cgi-script .cgi
       ## Optional where clause (fulltext search would be slow and
       ## database dependant).
       # SoundSoftwareDbWhereClause "and members.role_id IN (1,2)"
       ## Optional prefix for local repository URLs
       # SoundSoftwareRepoPrefix "/var/hg/"
  </Location>

See the original Redmine.pm for further configuration notes.

=cut

use strict;
use warnings FATAL => 'all', NONFATAL => 'redefine';

use DBI;
use Digest::SHA1;
use Authen::Simple::LDAP;
use Apache2::Module;
use Apache2::Access;
use Apache2::ServerRec qw();
use Apache2::RequestRec qw();
use Apache2::RequestUtil qw();
use Apache2::Const qw(:common :override :cmd_how);
use APR::Pool ();
use APR::Table ();

my @directives = (
  {
    name => 'SoundSoftwareDSN',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'Dsn in format used by Perl DBI. eg: "DBI:Pg:dbname=databasename;host=my.db.server"',
  },
  {
    name => 'SoundSoftwareDbUser',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'SoundSoftwareDbPass',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'SoundSoftwareDbWhereClause',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'SoundSoftwareRepoPrefix',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
  {
    name => 'SoundSoftwareSslRequired',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
  },
);

sub SoundSoftwareDSN { 
    my ($self, $parms, $arg) = @_;
    $self->{SoundSoftwareDSN} = $arg;
    my $query = "SELECT 
                 hashed_password, salt, auth_source_id, permissions
              FROM members, projects, users, roles, member_roles
              WHERE 
                projects.id=members.project_id
                AND member_roles.member_id=members.id
                AND users.id=members.user_id 
                AND roles.id=member_roles.role_id
                AND users.status=1 
                AND login=? 
                AND identifier=? ";
    $self->{SoundSoftwareQuery} = trim($query);
}

sub SoundSoftwareDbUser { set_val('SoundSoftwareDbUser', @_); }
sub SoundSoftwareDbPass { set_val('SoundSoftwareDbPass', @_); }
sub SoundSoftwareDbWhereClause { 
    my ($self, $parms, $arg) = @_;
    $self->{SoundSoftwareQuery} = trim($self->{SoundSoftwareQuery}.($arg ? $arg : "")." ");
}

sub SoundSoftwareRepoPrefix { 
    my ($self, $parms, $arg) = @_;
    if ($arg) {
	$self->{SoundSoftwareRepoPrefix} = $arg;
    }
}

sub SoundSoftwareSslRequired { set_val('SoundSoftwareSslRequired', @_); }

sub trim {
    my $string = shift;
    $string =~ s/\s{2,}/ /g;
    return $string;
}

sub set_val {
    my ($key, $self, $parms, $arg) = @_;
    $self->{$key} = $arg;
}

Apache2::Module::add(__PACKAGE__, \@directives);


my %read_only_methods = map { $_ => 1 } qw/GET PROPFIND REPORT OPTIONS/;

sub access_handler {
    my $r = shift;

    print STDERR "SoundSoftware.pm:$$: In access handler at " . scalar localtime() . "\n";

    unless ($r->some_auth_required) {
	$r->log_reason("No authentication has been configured");
	return FORBIDDEN;
    }

    my $method = $r->method;

    print STDERR "SoundSoftware.pm:$$: Method: $method, uri " . $r->uri . ", location " . $r->location . "\n";
    print STDERR "SoundSoftware.pm:$$: Accept: " . $r->headers_in->{Accept} . "\n";

    my $dbh = connect_database($r);
    unless ($dbh) {
	print STDERR "SoundSoftware.pm:$$: Database connection failed!: " . $DBI::errstr . "\n";
	return FORBIDDEN;
    }

    print STDERR "Connected to db, dbh is " . $dbh . "\n";

    my $project_id = get_project_identifier($dbh, $r);

    # We want to delegate most of the work to the authentication
    # handler (to ensure that user is asked to login even for 
    # nonexistent projects -- so they can't tell whether a private
    # project exists or not without authenticating). So 
    # 
    # * if the project is public
    #   - if the method is read-only
    #     + set handler to OK, no auth needed
    #   - if the method is not read-only
    #     + if the repo is read-only, return forbidden
    #     + else require auth
    # * if the project is not public or does not exist
    #     + require auth
    #
    # If we are requiring auth and are not currently https, and
    # https is required, then we must return a redirect to https
    # instead of an OK.

    my $status = get_project_status($dbh, $project_id, $r);
    my $readonly = project_repo_is_readonly($dbh, $project_id, $r);

    $dbh->disconnect();
    undef $dbh;

    my $auth_ssl_reqd = will_require_ssl_auth($r);

    if ($status == 1) { # public

	print STDERR "SoundSoftware.pm:$$: Project is public\n";

	if (!defined $read_only_methods{$method}) {

	    print STDERR "SoundSoftware.pm:$$: Method is not read-only\n";

	    if ($readonly) {
		print STDERR "SoundSoftware.pm:$$: Project repo is read-only, refusing access\n";
		return FORBIDDEN;
	    } else {
		print STDERR "SoundSoftware.pm:$$: Project repo is read-write, auth required\n";
		# fall through, this is the normal case
	    }

        } elsif ($auth_ssl_reqd and $r->unparsed_uri =~ m/cmd=branchmap/) {

            # A hac^H^H^Hspecial case. We want to ensure we switch to
            # https (if it will be necessarily for authentication) 
            # before the first POST request, and this is what I think
            # will give us suitable warning for Mercurial.

            print STDERR "SoundSoftware.pm:$$: Switching to HTTPS in preparation\n";
            # fall through, this is the normal case

	} else {
	    # Public project, read-only method -- this is the only
	    # case we can decide for certain to accept in this function
	    print STDERR "SoundSoftware.pm:$$: Method is read-only, no restriction here\n";
	    $r->set_handlers(PerlAuthenHandler => [\&OK]);
	    return OK;
	}

    } else { # status != 1, i.e. nonexistent or private -- equivalent here

	print STDERR "SoundSoftware.pm:$$: Project is private or nonexistent, auth required\n";
	# fall through
    }

    if ($auth_ssl_reqd) {
        my $redir_to = "https://" . $r->hostname() . $r->unparsed_uri();
        print STDERR "SoundSoftware.pm:$$: Need to switch to HTTPS, redirecting to $redir_to\n";
        $r->headers_out->add('Location' => $redir_to);
        return REDIRECT;
    } else {
        return OK;
    }
}

sub authen_handler {
    my $r = shift;
    
    print STDERR "SoundSoftware.pm:$$: In authentication handler at " . scalar localtime() . "\n";

    my $dbh = connect_database($r);
    unless ($dbh) {
        print STDERR "SoundSoftware.pm:$$: Database connection failed!: " . $DBI::errstr . "\n";
        return AUTH_REQUIRED;
    }
    
    my $project_id = get_project_identifier($dbh, $r);
    my $realm = get_realm($dbh, $project_id, $r);
    $r->auth_name($realm);

    my ($res, $redmine_pass) =  $r->get_basic_auth_pw();
    unless ($res == OK) {
	$dbh->disconnect();
	undef $dbh;
	return $res;
    }
    
    print STDERR "SoundSoftware.pm:$$: User is " . $r->user . ", got password\n";

    my $status = get_project_status($dbh, $project_id, $r);
    if ($status == 0) {
	# nonexistent, behave like private project you aren't a member of
	print STDERR "SoundSoftware.pm:$$: Project doesn't exist, not permitted\n";
	$dbh->disconnect();
	undef $dbh;
	$r->note_auth_failure();
	return AUTH_REQUIRED;
    }

    my $permitted = is_permitted($dbh, $project_id, $r->user, $redmine_pass, $r);
    
    $dbh->disconnect();
    undef $dbh;

    if ($permitted) {
	return OK;
    } else {
	print STDERR "SoundSoftware.pm:$$: Not permitted\n";
	$r->note_auth_failure();
	return AUTH_REQUIRED;
    }
}

sub get_project_status {
    my $dbh = shift;
    my $project_id = shift;
    my $r = shift;

    if (!defined $project_id or $project_id eq '') {
	return 0; # nonexistent
    }
    
    my $sth = $dbh->prepare(
        "SELECT is_public FROM projects WHERE projects.identifier = ?;"
    );

    $sth->execute($project_id);
    my $ret = 0; # nonexistent
    if (my @row = $sth->fetchrow_array) {
    	if ($row[0] eq "1" || $row[0] eq "t") {
	    $ret = 1; # public
    	} else {
	    $ret = 2; # private
	}
    }
    $sth->finish();
    undef $sth;

    $ret;
}

sub will_require_ssl_auth {
    my $r = shift;

    my $cfg = Apache2::Module::get_config
        (__PACKAGE__, $r->server, $r->per_dir_config);

    if ($cfg->{SoundSoftwareSslRequired} eq "on") {
        if ($r->dir_config('HTTPS') eq "on") {
            # already have ssl
            return 0;
        } else {
            # require ssl for auth, don't have it yet
            return 1;
        }
    } elsif ($cfg->{SoundSoftwareSslRequired} eq "off") {
        # don't require ssl for auth
        return 0;
    } else {
        print STDERR "WARNING: SoundSoftware.pm:$$: SoundSoftwareSslRequired should be either 'on' or 'off'\n";
        # this is safer
        return 1;
    }
}

sub project_repo_is_readonly {
    my $dbh = shift;
    my $project_id = shift;
    my $r = shift;

    if (!defined $project_id or $project_id eq '') {
        return 0; # nonexistent
    }

    my $sth = $dbh->prepare(
        "SELECT repositories.is_external FROM repositories, projects WHERE projects.identifier = ? AND repositories.project_id = projects.id;"
    );

    $sth->execute($project_id);
    my $ret = 0; # nonexistent
    if (my @row = $sth->fetchrow_array) {
        if (defined($row[0]) && ($row[0] eq "1" || $row[0] eq "t")) {
            $ret = 1; # read-only (i.e. external)
        } else {
            $ret = 0; # read-write
        }
    }
    $sth->finish();
    undef $sth;

    $ret;
}

sub is_permitted {
    my $dbh = shift;
    my $project_id = shift;
    my $redmine_user = shift;
    my $redmine_pass = shift;
    my $r = shift;

    my $pass_digest = Digest::SHA1::sha1_hex($redmine_pass);

    my $cfg = Apache2::Module::get_config
	(__PACKAGE__, $r->server, $r->per_dir_config);

    my $query = $cfg->{SoundSoftwareQuery};
    my $sth = $dbh->prepare($query);
    $sth->execute($redmine_user, $project_id);

    my $ret;
    while (my ($hashed_password, $salt, $auth_source_id, $permissions) = $sth->fetchrow_array) {

	# Test permissions for this user before we verify credentials
	# -- if the user is not permitted this action anyway, there's
	# not much point in e.g. contacting the LDAP

	my $method = $r->method;

	if ((defined $read_only_methods{$method} && $permissions =~ /:browse_repository/)
	    || $permissions =~ /:commit_access/) {

	    # User would be permitted this action, if their
	    # credentials checked out -- test those now

	    print STDERR "SoundSoftware.pm: User $redmine_user has required role, checking credentials\n";

	    unless ($auth_source_id) {
                my $salted_password = Digest::SHA1::sha1_hex($salt.$pass_digest);
		if ($hashed_password eq $salted_password) {
		    print STDERR "SoundSoftware.pm: User $redmine_user authenticated via password\n";
		    $ret = 1;
		    last;
		}
	    } else {
		my $sthldap = $dbh->prepare(
		    "SELECT host,port,tls,account,account_password,base_dn,attr_login FROM auth_sources WHERE id = ?;"
		    );
		$sthldap->execute($auth_source_id);
		while (my @rowldap = $sthldap->fetchrow_array) {
		    my $ldap = Authen::Simple::LDAP->new(
			host    => ($rowldap[2] eq "1" || $rowldap[2] eq "t") ? "ldaps://$rowldap[0]" : $rowldap[0],
			port    => $rowldap[1],
			basedn  => $rowldap[5],
			binddn  => $rowldap[3] ? $rowldap[3] : "",
			bindpw  => $rowldap[4] ? $rowldap[4] : "",
			filter  => "(".$rowldap[6]."=%s)"
			);
		    if ($ldap->authenticate($redmine_user, $redmine_pass)) {
			print STDERR "SoundSoftware.pm:$$: User $redmine_user authenticated via LDAP\n";
			$ret = 1;
		    }
		}
		$sthldap->finish();
		undef $sthldap;
	    }
	} else {
	    print STDERR "SoundSoftware.pm:$$: User $redmine_user lacks required role for this project\n";
	}
    }

    $sth->finish();
    undef $sth;

    $ret;
}

sub get_project_identifier {
    my $dbh = shift;
    my $r = shift;

    my $location = $r->location;
    my ($repo) = $r->uri =~ m{$location/*([^/]+)};

    return $repo if (!$repo);

    $repo =~ s/[^a-zA-Z0-9\._-]//g;

    # The original Redmine.pm returns the string just calculated as
    # the project identifier.  That won't do for us -- we may have
    # (and in fact already do have, in our test instance) projects
    # whose repository names differ from the project identifiers.

    # This is a rather fundamental change because it means that almost
    # every request needs more than one database query -- which
    # prompts us to start passing around $dbh instead of connecting
    # locally within each function as is done in Redmine.pm.

    my $sth = $dbh->prepare(
        "SELECT projects.identifier FROM projects, repositories WHERE repositories.project_id = projects.id AND repositories.url LIKE ?;"
    );

    my $cfg = Apache2::Module::get_config
	(__PACKAGE__, $r->server, $r->per_dir_config);

    my $prefix = $cfg->{SoundSoftwareRepoPrefix};
    if (!defined $prefix) { $prefix = '%/'; }

    my $identifier = '';

    $sth->execute($prefix . $repo);
    my $ret = 0;
    if (my @row = $sth->fetchrow_array) {
	$identifier = $row[0];
    }
    $sth->finish();
    undef $sth;

    print STDERR "SoundSoftware.pm:$$: Repository '$repo' belongs to project '$identifier'\n";

    $identifier;
}

sub get_realm {
    my $dbh = shift;
    my $project_id = shift;
    my $r = shift;

    my $sth = $dbh->prepare(
        "SELECT projects.name FROM projects WHERE projects.identifier = ?;"
    );

    my $name = $project_id;

    $sth->execute($project_id);
    my $ret = 0;
    if (my @row = $sth->fetchrow_array) {
	$name = $row[0];
    }
    $sth->finish();
    undef $sth;

    # be timid about characters not permitted in auth realm and revert
    # to project identifier if any are found
    if ($name =~ m/[^\w\d\s\._-]/) {
	$name = $project_id;
    } elsif ($name =~ m/^\s*$/) {
	# empty or whitespace
	$name = $project_id;
    }
    
    if ($name =~ m/^\s*$/) {
        # nothing even in $project_id -- probably a nonexistent project.
        # use repo name instead (don't want to admit to user that project
        # doesn't exist)
        my $location = $r->location;
        my ($repo) = $r->uri =~ m{$location/*([^/]+)};
        $name = $repo;
    }

    my $realm = '"Mercurial repository for ' . "'$name'" . '"';

    $realm;
}

sub connect_database {
    my $r = shift;
    
    my $cfg = Apache2::Module::get_config
	(__PACKAGE__, $r->server, $r->per_dir_config);

    return DBI->connect($cfg->{SoundSoftwareDSN},
	                $cfg->{SoundSoftwareDbUser},
		        $cfg->{SoundSoftwareDbPass});
}

1;
