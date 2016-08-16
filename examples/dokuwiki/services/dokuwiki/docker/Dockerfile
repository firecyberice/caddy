FROM alpine:3.3

RUN apk add --update-cache --update \
php-cli \
php-mysqli \
php-ctype \
php-xml \
php-gd \
php-zlib \
php-openssl \
php-curl \
php-opcache \
php-json \
php-ldap \
curl

ENV VERSION=dokuwiki-2015-08-10a

# download dokuwiki
RUN \
curl -L -o tmp.tar.gz http://download.dokuwiki.org/src/dokuwiki/$VERSION.tgz \
&& tar xz -C / -f tmp.tar.gz \
&& rm -f tmp.tar.gz \
&& mv /dokuwiki* /dokuwiki \
&& mkdir /dokuwiki-data /dokuwiki-conf \
&& cp -r /dokuwiki/data/* /dokuwiki-data/ \
&& cp -r /dokuwiki/conf/* /dokuwiki-conf/

# create preload.php
COPY ./preload.php /dokuwiki/inc/preload.php

# add savedir option to local configuration
# create ACLs
# create default users
COPY ./conf/ /dokuwiki-conf/

WORKDIR /dokuwiki
EXPOSE 80
#VOLUME ["/dokuwiki-data", "/dokuwiki-conf"]
CMD php -S 0.0.0.0:80 -t /dokuwiki/
