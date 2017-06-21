FROM phusion/baseimage:0.9.18
MAINTAINER Derilinx

# Disable SSH
RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

ENV HOME /root
ENV CKAN_HOME /usr/lib/ckan/default
ENV CKAN_CONFIG /etc/ckan/default
ENV CKAN_DATA /var/lib/ckan
ENV CKAN_EXTENSIONS /usr/lib/ckan-extensions

# Install required packages
RUN apt-get -q -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get -q -y install \
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
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        libgeos-c1 \
        libgeos-dev \
        postgresql-client

# Install CKAN
RUN virtualenv $CKAN_HOME
RUN mkdir -p $CKAN_HOME $CKAN_CONFIG $CKAN_DATA
RUN chown www-data:www-data $CKAN_DATA

ADD ./ckan-home/requirements.txt $CKAN_HOME/src/ckan/requirements.txt
RUN $CKAN_HOME/bin/pip install --upgrade -r $CKAN_HOME/src/ckan/requirements.txt
ADD ./ckan-home $CKAN_HOME/src/ckan/
RUN $CKAN_HOME/bin/pip install -e $CKAN_HOME/src/ckan/
RUN ln -s $CKAN_HOME/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini
ADD ./etc/apache.wsgi $CKAN_CONFIG/apache.wsgi

# Install extensions
# local ones first, more likely to fail
ADD ./extensions $CKAN_EXTENSIONS
RUN $CKAN_HOME/bin/pip install -e  $CKAN_EXTENSIONS/ckanext-dietstars/
RUN $CKAN_HOME/bin/pip install -e  $CKAN_EXTENSIONS/ckanext-nrgi/
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-geoview.git#egg=ckanext-geoview'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/jqnatividad/ckanext-officedocs.git#egg=ckanext-officedocs'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-spatial.git#egg=ckanext-spatial'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-spatial/pip-requirements.txt
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-pdfview.git#egg=ckanext-pdfview'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-pages.git#egg=ckanext-pages'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-dcat.git#egg=ckanext-dcat'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-dcat/requirements.txt
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/keitaroinc/ckanext-s3filestore.git@boto3-fix#egg=ckanext-s3filestore'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-s3filestore/requirements.txt
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-scheming.git#egg=ckanext-scheming'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-scheming/requirements.txt

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
CMD ["/sbin/my_init"]

# Volumes
#VOLUME ["/etc/ckan/default"]
#VOLUME ["/var/lib/ckan"]
EXPOSE 80

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
