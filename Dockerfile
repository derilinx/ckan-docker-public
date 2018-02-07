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
        python-gdal \
        libevent-dev \
        libpq-dev \
        nginx-light \
        apache2 \
        libapache2-mod-wsgi \
        apache2-utils \
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
        postgresql-client \
        libmagickwand-dev \
        unzip \
        unrar \
        p7zip-full \
        wget \
        supervisor

# Install CKAN
RUN virtualenv $CKAN_HOME
RUN mkdir -p $CKAN_HOME $CKAN_CONFIG $CKAN_DATA
RUN chown www-data:www-data $CKAN_DATA

ADD ./ckan-home/requirement-setuptools.txt $CKAN_HOME/src/ckan/requirement-setuptools.txt
RUN $CKAN_HOME/bin/pip install --upgrade -r $CKAN_HOME/src/ckan/requirement-setuptools.txt
ADD ./ckan-home/requirements.txt $CKAN_HOME/src/ckan/requirements.txt
RUN $CKAN_HOME/bin/pip install --upgrade -r $CKAN_HOME/src/ckan/requirements.txt
ADD ./ckan-home/dev-requirements.txt $CKAN_HOME/src/ckan/dev-requirements.txt
RUN $CKAN_HOME/bin/pip install --upgrade -r $CKAN_HOME/src/ckan/dev-requirements.txt
ADD ./ckan-home $CKAN_HOME/src/ckan/
RUN $CKAN_HOME/bin/pip install -e $CKAN_HOME/src/ckan/
RUN ln -s $CKAN_HOME/src/ckan/ckan/config/who.ini $CKAN_CONFIG/who.ini
ADD ./etc/apache.wsgi $CKAN_CONFIG/apache.wsgi

# Install extensions
# local ones first, more likely to fail
ADD ./extensions $CKAN_EXTENSIONS
#Useful extensions
#NB no real need to have this as a submodule anymore
RUN $CKAN_HOME/bin/pip install -e  $CKAN_EXTENSIONS/ckanext-dietstars/
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-pdfview.git#egg=ckanext-pdfview'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-pages.git#egg=ckanext-pages'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-dcat.git#egg=ckanext-dcat'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-dcat/requirements.txt
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/jqnatividad/ckanext-officedocs.git#egg=ckanext-officedocs'
#Standard CKAN geospatial stuff
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-geoview.git#egg=ckanext-geoview'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-spatial.git#egg=ckanext-spatial'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-spatial/pip-requirements.txt
#Stuff from ODM CKAN, ported to CKAN > 2.6 where needed
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-fluent.git#egg=ckanext-fluent'
#Their issues had diverged so much from CKAN's for now we just fixed the problems for CKAN 2.6 in a fork
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-issues.git#egg=ckanext-issues'
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/ckan/ckanext-scheming.git#egg=ckanext-scheming'
RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-scheming/requirements.txt
#RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-odm_laws.git#egg=ckanext-odm_laws'
#RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-odm-laws/requirements.txt
#RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-odm_library.git#egg=ckanext-odm_library'
#RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-odm-library/requirements.txt
#RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-odm_nav.git#egg=ckanext-odm_nav'
#RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-odm-nav/requirements.txt
#RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-odm_dataset.git#egg=ckanext-odm_dataset'
#RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-odm-dataset/requirements.txt
#RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/OpenDevelopmentMekong/ckanext-odm_audit.git#egg=ckanext-odm_audit'
#RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-odm-audit/requirements.txt
#RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/OpenDevelopmentMekong/ckanext-odm_migration.git#egg=ckanext-odm_migration'
#RUN $CKAN_HOME/bin/pip install -r /usr/lib/ckan/default/src/ckanext-odm-migration/requirements.txt
#Vectorstorer for using CKAN as the entrypoint for creating GeoServer resource
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/ckanext-vectorstorer.git#egg=ckanext-vectorstorer'
#This gives us trusted host and a better implementation of the subdirectory option for git (see below)
RUN $CKAN_HOME/bin/pip install --upgrade pip
#Don't verify silly Sourceforge
RUN $CKAN_HOME/bin/pip install --trusted-host netix.dl.sourceforge.net -r /usr/lib/ckan/default/src/ckanext-vectorstorer/pip-requirements.txt
#TerriaJS for previewing
RUN $CKAN_HOME/bin/pip install -e 'git+https://github.com/derilinx/TerriaMap.git#egg=cesiumpreview&subdirectory=ckanextcesiumpreview'
#Patch in things from the bigger publicamundi
RUN mkdir -p /usr/lib/ckan/default/src/ckanext-vectorstorer/ckanext/publicamundi/model
WORKDIR /usr/lib/ckan/default/src/ckanext-vectorstorer/ckanext/publicamundi
RUN wget https://raw.githubusercontent.com/PublicaMundi/ckanext-publicamundi/bdd4d6d6c8473a180127b419df9547bed6c89a23/ckanext/publicamundi/__init__.py
WORKDIR /usr/lib/ckan/default/src/ckanext-vectorstorer/ckanext/publicamundi/model
RUN wget https://raw.githubusercontent.com/PublicaMundi/ckanext-publicamundi/bdd4d6d6c8473a180127b419df9547bed6c89a23/ckanext/publicamundi/model/__init__.py
RUN wget https://raw.githubusercontent.com/PublicaMundi/ckanext-publicamundi/bdd4d6d6c8473a180127b419df9547bed6c89a23/ckanext/publicamundi/model/csw_record.py
RUN wget https://raw.githubusercontent.com/derilinx/ckanext-publicamundi/c1590e89d7c50509ea7cb5dee2189614e10a1ca2/ckanext/publicamundi/model/resource_identify.py
RUN $CKAN_HOME/bin/pip uninstall -y geoalchemy
#Bring in a pull request for geoalchemy so that it works with modern sqlalchemy
RUN $CKAN_HOME/bin/pip install 'git+https://github.com/chokoswitch/geoalchemy.git#egg=geoalchemy'
RUN $CKAN_HOME/bin/pip install -e  $CKAN_EXTENSIONS/ckanext-landesa/


# http://serverfault.com/a/711172
# get apache logs in docker-compose logs ckan
RUN ln -sf /proc/self/fd/1 /var/log/apache2/ckan_default.custom.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/ckan_default.error.log

# Configure the rest of apache
ADD ./etc/apache.conf /etc/apache2/sites-available/ckan_default.conf
RUN echo "Listen 8080" > /etc/apache2/ports.conf
RUN a2ensite ckan_default
RUN a2dissite 000-default

# Configure Supervisor (Jobs queue)
ADD ./etc/supervisor-ckan-worker.conf /etc/supervisor/conf.d/supervisor-ckan-worker.conf

# Configure nginx
# if you have an ssl cert in /contrib/docker/ssl/server.{key,crt}, uncomment these
# and uncomment the lines in /contrib/docker/nginx.conf
# ADD ./contrib/docker/ssl/server.key /etc/nginx/ssl/server.key
# ADD ./contrib/docker/ssl/server.crt /etc/nginx/ssl/server.crt
# if you want to password protect the deployment, uncomment this line and edit the .htpasswd file later:
# htpasswd /etc/nginx/.htpasswd protected
# to change the password for the user "protected". Default password is "protected"
# and uncomment the relevant lines in /contrib/docker/nginx.conf
ADD ./etc/.htpasswd /etc/nginx/.htpasswd
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
