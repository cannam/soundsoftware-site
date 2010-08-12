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
       ## Optional credentials cache size
       # SoundSoftwareCacheCredsMax 50
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

# use Apache2::Directive qw();

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
    name => 'SoundSoftwareCacheCredsMax',
    req_override => OR_AUTHCFG,
    args_how => TAKE1,
    errmsg => 'SoundSoftwareCacheCredsMax must be decimal number',
  },
);

sub SoundSoftwareDSN { 
  my ($self, $parms, $arg) = @_;
  $self->{SoundSoftwareDSN} = $arg;
  my $query = "SELECT 
                 hashed_password, auth_source_id, permissions
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

sub SoundSoftwareCacheCredsMax { 
  my ($self, $parms, $arg) = @_;
  if ($arg) {
    $self->{SoundSoftwareCachePool} = APR::Pool->new;
    $self->{SoundSoftwareCacheCreds} = APR::Table::make($self->{SoundSoftwareCachePool}, $arg);
    $self->{SoundSoftwareCacheCredsCount} = 0;
    $self->{SoundSoftwareCacheCredsMax} = $arg;
  }
}

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

  print STDERR "SoundSoftware.pm: In access handler\n";

  unless ($r->some_auth_required) {
      $r->log_reason("No authentication has been configured");
      return FORBIDDEN;
  }

  my $method = $r->method;

  print STDERR "SoundSoftware.pm: Method: $method, uri " . $r->uri . ", location " . $r->location . "\n";

  if (!defined $read_only_methods{$method}) {
      print STDERR "SoundSoftware.pm: Method is not read-only, authentication handler required\n";
      return OK;
  }

  my $project_id = get_project_identifier($r);

  if (defined $project_id) {
      print STDERR "SoundSoftware.pm: Project: $project_id\n";
  } else {
      print STDERR "SoundSoftware.pm: No project identifier available, refusing access\n";
      return FORBIDDEN;
  }

  my $status = get_project_status($project_id, $r);

  if ($status == 0) { # nonexistent
      print STDERR "SoundSoftware.pm: Project does not exist, refusing access\n";
      return FORBIDDEN;
  } elsif ($status == 1) { # public
      print STDERR "SoundSoftware.pm: Project is public, no restriction here\n";
      $r->set_handlers(PerlAuthenHandler => [\&OK])
  } else { # private
      print STDERR "SoundSoftware.pm: Project is not public, authentication handler required\n";
  }

  return OK
}

sub authen_handler {
  my $r = shift;
 
  print STDERR "SoundSoftware.pm: In authentication handler\n";
 
  my ($res, $redmine_pass) =  $r->get_basic_auth_pw();
  return $res unless $res == OK;
  
  print STDERR "SoundSoftware.pm: User is " . $r->user . ", got password\n";

  if (is_member($r->user, $redmine_pass, $r)) {
      return OK;
  } else {
      print STDERR "SoundSoftware.pm: Failed to validate project membership\n";
      $r->note_auth_failure();
      return AUTH_REQUIRED;
  }
}

sub get_project_status {
    my $project_id = shift;
    my $r = shift;
    
    my $dbh = connect_database($r);
    my $sth = $dbh->prepare(
        "SELECT is_public FROM projects WHERE projects.identifier = ?;"
    );

    $sth->execute($project_id);
    my $ret = 0;
    if (my @row = $sth->fetchrow_array) {
    	if ($row[0] eq "1" || $row[0] eq "t") {
	    $ret = 1; # public
    	} else {
	    $ret = 2; # private (0 means nonexistent)
	}
    }
    $sth->finish();
    undef $sth;
    $dbh->disconnect();
    undef $dbh;

    $ret;
}

sub is_member {
  my $redmine_user = shift;
  my $redmine_pass = shift;
  my $r = shift;

  my $dbh         = connect_database($r);
  my $project_id  = get_project_identifier($r);

  my $pass_digest = Digest::SHA1::sha1_hex($redmine_pass);

  my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
  my $usrprojpass;
  if ($cfg->{SoundSoftwareCacheCredsMax}) {
    $usrprojpass = $cfg->{SoundSoftwareCacheCreds}->get($redmine_user.":".$project_id);
    return 1 if (defined $usrprojpass and ($usrprojpass eq $pass_digest));
  }
  my $query = $cfg->{SoundSoftwareQuery};
  my $sth = $dbh->prepare($query);
  $sth->execute($redmine_user, $project_id);

  my $ret;
  while (my ($hashed_password, $auth_source_id, $permissions) = $sth->fetchrow_array) {

      unless ($auth_source_id) {
	  my $method = $r->method;
          if ($hashed_password eq $pass_digest && ((defined $read_only_methods{$method} && $permissions =~ /:browse_repository/) || $permissions =~ /:commit_access/) ) {
              $ret = 1;
              last;
          }
      } else {
          my $sthldap = $dbh->prepare(
              "SELECT host,port,tls,account,account_password,base_dn,attr_login from auth_sources WHERE id = ?;"
          );
          $sthldap->execute($auth_source_id);
          while (my @rowldap = $sthldap->fetchrow_array) {
            my $ldap = Authen::Simple::LDAP->new(
                host    =>      ($rowldap[2] eq "1" || $rowldap[2] eq "t") ? "ldaps://$rowldap[0]" : $rowldap[0],
                port    =>      $rowldap[1],
                basedn  =>      $rowldap[5],
                binddn  =>      $rowldap[3] ? $rowldap[3] : "",
                bindpw  =>      $rowldap[4] ? $rowldap[4] : "",
                filter  =>      "(".$rowldap[6]."=%s)"
            );
            my $method = $r->method;
            $ret = 1 if ($ldap->authenticate($redmine_user, $redmine_pass) && ((defined $read_only_methods{$method} && $permissions =~ /:browse_repository/) || $permissions =~ /:commit_access/));

          }
          $sthldap->finish();
          undef $sthldap;
      }
  }
  $sth->finish();
  undef $sth;
  $dbh->disconnect();
  undef $dbh;

  if ($cfg->{SoundSoftwareCacheCredsMax} and $ret) {
    if (defined $usrprojpass) {
      $cfg->{SoundSoftwareCacheCreds}->set($redmine_user.":".$project_id, $pass_digest);
    } else {
      if ($cfg->{SoundSoftwareCacheCredsCount} < $cfg->{SoundSoftwareCacheCredsMax}) {
        $cfg->{SoundSoftwareCacheCreds}->set($redmine_user.":".$project_id, $pass_digest);
        $cfg->{SoundSoftwareCacheCredsCount}++;
      } else {
        $cfg->{SoundSoftwareCacheCreds}->clear();
        $cfg->{SoundSoftwareCacheCredsCount} = 0;
      }
    }
  }

  $ret;
}

sub get_project_identifier {
    my $r = shift;

    my $location = $r->location;
    my ($repo) = $r->uri =~ m{$location/*([^/]+)};
    $repo =~ s/[^a-zA-Z0-9\._-]//g;

    my $dbh = connect_database($r);
    my $sth = $dbh->prepare(
        "SELECT projects.identifier FROM projects, repositories WHERE repositories.project_id = projects.id AND repositories.url LIKE ?;"
    );

    my $identifier = '';

    $sth->execute('%/' . $repo);
    my $ret = 0;
    if (my @row = $sth->fetchrow_array) {
	$identifier = $row[0];
    }
    $sth->finish();
    undef $sth;
    $dbh->disconnect();
    undef $dbh;

    print STDERR "SoundSoftware.pm: Repository $repo belongs to project $identifier\n";

    $identifier;
}

sub connect_database {
    my $r = shift;
    
    my $cfg = Apache2::Module::get_config(__PACKAGE__, $r->server, $r->per_dir_config);
    return DBI->connect($cfg->{SoundSoftwareDSN}, $cfg->{SoundSoftwareDbUser}, $cfg->{SoundSoftwareDbPass});
}

1;
