
# For documentation and experimental purposes only. As a
# reconstruction of the machine image that runs this application,
# there are lots of things missing here; but as a good Docker
# configuration, it fails by mixing together rather a lot of concerns.

FROM ubuntu:16.04
MAINTAINER Chris Cannam <cannam@all-day-breakfast.com>

RUN apt-get update && \
    apt-get install -y \
    apache2 \
    apache2-dev \
    apt-utils \
    build-essential \
    cron \
    curl \
    doxygen \
    exim4 \
    git \
    graphviz \
    imagemagick \
    libapache-dbi-perl \
    libapache2-mod-perl2 \
    libapr1-dev \
    libaprutil1-dev \
    libauthen-simple-ldap-perl \
    libcurl4-openssl-dev \
    libdbd-pg-perl \
    libpq-dev \
    libmagickwand-dev \
    libio-socket-ssl-perl \
    logrotate \
    mercurial \
    postgresql \
    rsync \
    ruby \
    ruby-dev \
    sudo

# Also used on the live site, for javadoc extraction, but this is
# would be by far the biggest package here: let's omit it while we're
# not making use of it
#   openjdk-9-jdk-headless

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


# Passenger gets installed through gem, not apt

RUN gem install passenger -v 4.0.60 --no-rdoc --no-ri
RUN passenger-install-apache2-module --languages=ruby


# Copy across webapp, set up ownership

COPY . /var/www/code

RUN groupadd code
RUN useradd -g code -G www-data code
RUN chown -R code.www-data /var/www/code
RUN find /var/www/code -type d -exec chmod g+s \{\} \;


# Initialise /var/hg (in reality this would be mounted from somewhere)

RUN mkdir -p /var/hg
RUN chown code.www-data /var/hg
RUN chmod g+s /var/hg
COPY extra/soundsoftware/dockertest/index.cgi /var/hg/
COPY extra/soundsoftware/dockertest/hgweb.config /var/hg/
RUN chmod +x /var/hg/index.cgi


# We're based in the code webapp directory from here on

WORKDIR /var/www/code


# Set up database config etc

RUN cp extra/soundsoftware/dockertest/database.yml.interpolated config/database.yml


# Install Rails and dependencies (database.yml must be populated before this)

RUN gem install bundler
RUN bundle install


# Initialise Redmine token (bundler must be installed before this)

RUN bundle exec rake generate_secret_token


# Import Postgres database from postgres-dumpall file

RUN chown postgres postgres-dumpall
RUN /etc/init.d/postgresql start && sudo -u postgres psql -f postgres-dumpall postgres


# Install Perl auth module for Hg access

RUN mkdir -p /usr/local/lib/site_perl/Apache/Authn/
RUN cp extra/soundsoftware/SoundSoftware.pm /usr/local/lib/site_perl/Apache/Authn/


# Set up Apache config (todo: insert variables)

RUN rm -f /etc/apache2/sites-enabled/000-default.conf

RUN cp extra/soundsoftware/dockertest/passenger.conf /etc/apache2/mods-available/
RUN cp extra/soundsoftware/dockertest/passenger.load /etc/apache2/mods-available/
RUN cp extra/soundsoftware/dockertest/perl.conf      /etc/apache2/mods-available/

RUN ln -s ../mods-available/passenger.conf  /etc/apache2/mods-enabled/
RUN ln -s ../mods-available/passenger.load  /etc/apache2/mods-enabled/
RUN ln -s ../mods-available/perl.conf       /etc/apache2/mods-enabled/
RUN ln -s ../mods-available/expires.load    /etc/apache2/mods-enabled/
RUN ln -s ../mods-available/rewrite.load    /etc/apache2/mods-enabled/
RUN ln -s ../mods-available/cgi.load        /etc/apache2/mods-enabled/

RUN cp extra/soundsoftware/dockertest/code.conf.interpolated /etc/apache2/sites-available/code.conf
RUN ln -s ../sites-available/code.conf /etc/apache2/sites-enabled/10-code.conf

RUN apache2ctl configtest


# Start Postgres and foregrounded Apache

RUN echo "#!/bin/bash"                      > container-run.sh
RUN echo "/etc/init.d/postgresql start"    >> container-run.sh
RUN echo "apache2ctl -D FOREGROUND"        >> container-run.sh
RUN chmod +x container-run.sh

EXPOSE 80
CMD ./container-run.sh

