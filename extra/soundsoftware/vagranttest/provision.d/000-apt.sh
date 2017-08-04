#!/bin/bash

set -e

apt-get update && \
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
