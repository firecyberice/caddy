# 5

read -r -d '' INST_GITIGNORE <<EOM
# ignore logs
logs/

# tls certs
letsencrypt/
acme/
ocsp/

# hugo binary
bin/

EOM

read -r -d '' INST_DOCKERFILE <<"EOM"

ENV OPENSSL_VERSION 1.0.2e-r0

RUN apk upgrade --no-cache --available && \
apk add --no-cache \
ca-certificates \
curl \
git \
openssh-client \
"openssl>=${OPENSSL_VERSION}"

ENV BASEURL="https://caddyserver.com/download/build?os=linux" \
    FEATURES="cors%2Cfilemanager%2Cgit%2Chugo%2Cipfilter%2Cjwt%2Clocale%2Cminify%2Cratelimit%2Crealip%2Cupload"
ARG ARCH
ENV ARCH ${ARCH:-amd64}
ENV URL="${BASEURL}&arch=${ARCH}&features=${FEATURES}"

RUN \
curl -sL "${URL}" > /tmp/caddy.tar.gz  && \
    tar xzC /usr/sbin/ -f /tmp/caddy.tar.gz caddy && \
    rm -f /tmp/caddy.tar.gz

# Fix to use git plugin
RUN mkdir /root/.ssh \
    && echo -e "\
StrictHostKeyChecking no\\n\
UserKnownHostsFile /dev/null\\n\
    " > /root/.ssh/config

#RUN adduser -Du 1000 caddy \
#    && mkdir /home/caddy/.ssh \
#    && cp /root/.ssh/config /home/caddy/.ssh/config
#USER caddy
EXPOSE 80 443 2015
ENTRYPOINT ["caddy"]

EOM


read -r -d '' INST_CADDYFILE <<EOM
start.domain.tld:80 , :80 {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
log / /data/logs/caddy.log "[startpage] - {when} - {remote} - {proto} {method} - {status} {size}"
  root /data/www
  minify

#  errors {
#    log /data/logs/error.log
#    403 errors/403.html # Forbidden
#    404 errors/404.html # Not Found
#    408 errors/408.html # Request Time-out
#    500 errors/500.html # Internal Server Error
#    501 errors/501.html # Not Implemented
#    502 errors/502.html # Bad Gateway
#    503 errors/503.html # Service Unavailable
#    504 errors/504.html # Gateway Time-out
#  }
}

import  /data/conf/enabled/*

EOM

read -r -d '' INST_COMPOSE <<EOM
version: "2"
networks:
  backend:
    external:
      name: ${NETWORK}

services:
  caddy:
    image: firecyberice/caddy:frontend
    restart: on-failure:5
    #    read_only: true
    cap_add:
      - NET_BIND_SERVICE
    user: root
    ports:
      - 80:80
      - 443:443
    networks:
      - backend
    command: -http2=false -log stdout -conf /data/conf/caddyfile
    working_dir: /data
    environment:
      - CADDYPATH=/data
    volumes:
      - ./caddy:/data
      - ./caddy/bin:/root/.caddy/bin

EOM
