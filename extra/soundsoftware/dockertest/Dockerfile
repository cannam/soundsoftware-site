
# For documentation and experimental purposes only. As a
# reconstruction of the machine image that runs this application,
# there are lots of things missing here; meanwhile as a good Docker
# configuration, it fails in mixing together rather a lot of concerns.

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
    openjdk-9-jdk-headless \
    postgresql \
    rsync \
    ruby \
    ruby-dev \
    sudo \
    supervisor


# Passenger gets installed through gem, not apt

RUN gem install passenger -v 4.0.60 --no-rdoc --no-ri
RUN passenger-install-apache2-module --languages=ruby


# Copy across webapp, set up ownership

COPY . /var/www/code

RUN groupadd code
RUN useradd -g code -G www-data code
RUN chown -R code.www-data /var/www/code
RUN find /var/www/code -type d -exec chmod g+s \{\} \;


# We're based in the code webapp directory from here on

WORKDIR /var/www/code


# Set up Apache config and webapp database config (todo: insert variables)

RUN cp extra/soundsoftware/dockertest/code.conf /etc/apache2/sites-available/
RUN cp extra/soundsoftware/dockertest/database.yml config/database.yml


# Install Rails dependencies (database.yml must be populated before this)

RUN gem install bundler
RUN bundle install


# Import Postgres database from postgres-dumpall file

RUN chown postgres postgres-dumpall
RUN /etc/init.d/postgresql start && \
  sudo -u postgres psql -f postgres-dumpall postgres


# Install Perl auth module for Hg access

RUN mkdir -p /usr/local/lib/site_perl/Apache/Authn/
RUN cp extra/soundsoftware/SoundSoftware.pm /usr/local/lib/site_perl/Apache/Authn/


# Enable site for Apache

RUN ln -s ../sites-available/code.conf /etc/apache2/sites-enabled/10-code.conf
RUN apache2ctl configtest
