#!/bin/bash

set -e

# Install necessary system packages. This assumes we are deploying on
# Ubuntu 16.04.

# We aim to make all of these provisioning scripts non-destructive if
# run more than once. In this case, running the script again will
# install any outstanding updates.

apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y \
            ack-grep \
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
            mercurial-git \
            openjdk-9-jdk-headless \
            postgresql \
            rsync \
            ruby \
            ruby-dev \
            sudo

locale-gen en_US.UTF-8


