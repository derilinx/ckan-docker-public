FROM phusion/baseimage:bionic-1.0.0
MAINTAINER Derilinx

# Disable SSH
RUN DEBIAN_FRONTEND=noninteractive apt-get -qy remove openssh-server openssh-sftp-server && \
    rm -r /etc/service/sshd || true && \
    rm /etc/my_init.d/00_regen_ssh_host_keys.sh || true

RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -

ENV HOME /root
ENV CKAN_HOME /usr/lib/ckan/default
ENV CKAN_CONFIG /etc/ckan/default
ENV CKAN_DATA /var/lib/ckan
ENV CKAN_EXTENSIONS /usr/lib/ckan-extensions

# Install required packages
RUN apt-get -q -y update && \
   DEBIAN_FRONTEND=noninteractive apt-get -qy -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"  dist-upgrade && \
   DEBIAN_FRONTEND=noninteractive apt-get -qy install \
        python-minimal \
        python-dev \
        python-virtualenv \
        libevent-dev \
        libpq-dev \
        nginx-light \
        apache2 \
        libapache2-mod-wsgi \
        postfix \
        build-essential \
        git \
        ack-grep \
        vim \
        emacs-nox \
        tzdata \
        curl \
        gettext\
        nodejs \
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        libgeos-c1v5 \
        libgeos-dev \
        postgresql-client

# install less
WORKDIR $CKAN_HOME/src/ckan
RUN npm install less

# Install CKAN
RUN virtualenv $CKAN_HOME
RUN mkdir -p $CKAN_HOME $CKAN_CONFIG $CKAN_DATA $CKAN_DATA/storage/uploads
RUN chown -R www-data:www-data $CKAN_DATA

ADD ./ckan-upstream $CKAN_HOME/src/ckan/
ADD ./ckan-home/requirements.txt ./ckan-home/dev-requirements.txt $CKAN_HOME/src/ckan/

RUN $CKAN_HOME/bin/pip install --upgrade 'setuptools==41.0.0'
RUN $CKAN_HOME/bin/pip install -v -v --use-feature=2020-resolver --upgrade \
    -r $CKAN_HOME/src/ckan/requirements.txt \
    -r $CKAN_HOME/src/ckan/dev-requirements.txt \
    -e $CKAN_HOME/src/ckan/
RUN ln -s $CKAN_HOME/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini
ADD ./etc/apache.wsgi $CKAN_CONFIG/apache.wsgi

# Install extensions
ADD ./extensions $CKAN_EXTENSIONS
RUN cd $CKAN_EXTENSIONS \
    && $CKAN_HOME/bin/pip -v -v install --use-feature=2020-resolver -r requirements.txt

RUN cd $CKAN_EXTENSIONS && $CKAN_HOME/bin/pip -v -v install --use-feature=2020-resolver -r indirect-requirements.txt

#add the patches
ADD ./core-patches-2.7.10 /usr/lib/ckan/default/src/ckan/core-patches-2.7.10
RUN cd /usr/lib/ckan/default/src/ckan && find core-patches-2.7.10 -name '*.patch' | sort | xargs -n 1 patch -p1 -i

ADD glyphicons.tgz ./ckan/public/base/vendor/bootstrap

# http://serverfault.com/a/711172
# get apache logs in docker-compose logs ckan
RUN ln -sf /proc/self/fd/1 /var/log/apache2/ckan_default.custom.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/ckan_default.error.log

# Configure the rest of apache
ADD ./etc/apache.conf /etc/apache2/sites-available/ckan_default.conf
RUN echo "Listen 8080" > /etc/apache2/ports.conf
RUN a2ensite ckan_default
RUN a2dissite 000-default

# Configure nginx
# if you have an ssl cert in /contrib/docker/ssl/server.{key,crt}, uncomment these
# and uncomment the lines in /contrib/docker/nginx.conf
# ADD ./contrib/docker/ssl/server.key /etc/nginx/ssl/server.key
# ADD ./contrib/docker/ssl/server.crt /etc/nginx/ssl/server.crt
ADD ./etc/nginx.conf /etc/nginx/nginx.conf
RUN mkdir /var/cache/nginx

# Configure postfix
# Hostname will be added to files later and postfix restarted
ADD ./etc/main.cf /etc/postfix/main.cf

# Configure runit
ADD ./etc/my_init.d/50_configure /etc/my_init.d
ADD ./etc/my_init.d/65_extensions /etc/my_init.d
ADD ./etc/my_init.d/70_initdb /etc/my_init.d
ADD ./etc/my_init.d/80_initadmin /etc/my_init.d
ADD ./etc/svc /etc/service
COPY version.txt $CKAN_HOME/
CMD ["/sbin/my_init"]

# Volumes
#VOLUME ["/etc/ckan/default"]
#VOLUME ["/var/lib/ckan"]
EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
