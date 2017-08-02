FROM ubuntu:16.04
MAINTAINER Chris Cannam <cannam@all-day-breakfast.com>
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    git mercurial \
    curl wget rsync libcurl4-openssl-dev \
    logrotate cron \
    apache2 apache2-dev libapr1-dev libaprutil1-dev \
    ruby ruby-dev \
    postgresql libpq-dev \
    openjdk-9-jdk-headless \
    libapache2-mod-perl2 \
    imagemagick libmagickwand-dev graphviz \
    doxygen \
    exim4
RUN groupadd code
RUN useradd -g code -G www-data code
RUN gem install passenger -v 4.0.60 --no-rdoc --no-ri
RUN passenger-install-apache2-module --languages=ruby
COPY . /var/www/code
RUN chown -R code.www-data /var/www/code
RUN find /var/www/code -type d -exec chmod g+x \{\} \;
WORKDIR /var/www/code
RUN echo \
'production:\n\
  adapter: postgresql\n\
  database: code\n\
  host: localhost\n\
  username: code\n\
  password: "example"\n' | sed 's/\\n/\n/g' > config/database.yml
RUN gem install bundler
RUN bundle install
RUN ps auxw|grep postgres
RUN apt-get install sudo
RUN chown postgres postgres-dumpall
RUN /etc/init.d/postgresql start && sudo -u postgres psql -f postgres-dumpall postgres
