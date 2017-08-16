#!/bin/bash

set -e

if [ -x /usr/bin/yum ]; then

    # Assumption: CentOS 7

    # This doesn't work -- I got hung up on the problem of making a
    # sufficiently recent Ruby act as the system /usr/bin/ruby without
    # massively overcomplicating things, and decided not to persist
    # with it

    yum install -y epel-release centos-release-scl && \
        yum update -y && \
        yum install -y \
            httpd \
            httpd-devel \
            gcc \
            gcc-c++ \
            curl \
            doxygen \
            git \
            mercurial \
            mod_perl \
            postgresql \
            rh-ruby24 \
            rh-ruby24-ruby-devel \
            rh-ruby24-rubygems \
            rh-ruby24-rubygems-devel \
            logrotate

    if [ -f /usr/bin/ruby ]; then
        yum remove -y ruby
    fi

    cat > /etc/profile.d/enableruby24.sh <<EOF
#!/bin/bash
source scl_source enable rh-ruby24
EOF
    
else

    # Assumption: Ubuntu 16.04

    # This is the working one!

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
                postgresql \
                rsync \
                ruby \
                ruby-dev \
                sudo

fi
