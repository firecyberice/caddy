# 5

read -r -d '' INST_GITIGNORE << EOM
# ignore logs
logs/

# tls certs
letsencrypt/

EOM

read -r -d '' INST_DOCKERFILE << EOM
FROM alpine:3.3

ENV OPENSSL_VERSION 1.0.2e-r0

RUN apk upgrade --no-cache --available && \
apk add --no-cache \
ca-certificates \
curl \
git \
"openssl>=${OPENSSL_VERSION}"

RUN \
curl -sL "https://caddyserver.com/download/build?os=linux&arch=amd64&features=cors%2Cgit%2Chugo%2Cipfilter%2Cjsonp" > /tmp/caddy.tar.gz  && \
tar xzC /usr/sbin/ -f /tmp/caddy.tar.gz caddy && \
rm -f /tmp/caddy.tar.gz

RUN adduser -Du 1000 caddy
VOLUME ["/etc/caddy","/home/caddy"]
USER caddy
EXPOSE 80 443 2015
ENTRYPOINT ["/usr/sbin/caddy"]

EOM


read -r -d '' INST_CADDYFILE << EOM
#debug.domain.tld {
#  log stdout
#  root /root/.caddy/startpage
#}
start.domain.tld:80 {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
  log / /root/.caddy/logs/landingpage.log "{proto} Request: {method} {path} ... {scheme} {host} {remote}"
  root /root/.caddy/landingpage
  errors {
  403 403.html # Forbidden
  404 404.html # Not Found
  408 408.html # Request Time-out
  500 500.html # Internal Server Error
  501 501.html # Not Implemented
  502 502.html # Bad Gateway
  503 503.html # Service Unavailable
  504 504.html # Gateway Time-out
}
}

import  /root/.caddy/conf/enabled/*
EOM

read -r -d '' INST_COMPOSE << EOM
version: "2"
networks:
  backend:
    external:
      name: caddy_backend

services:
  caddy:
    build:
      context: caddy/
      dockerfile: Dockerfile
    image: firecyberice/caddy:dirty
    command: -http2=false -conf /root/.caddy/conf/caddyfile
    restart: always
    #    read_only: true
    cap_add:
      - NET_BIND_SERVICE
    user: root
    ports:
      - 80:80
      - 443:443
    networks:
      - backend
    volumes:
      - ./caddy/:/root/.caddy:rw
EOM
