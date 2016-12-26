# 4

read -r -d '' INST_GITIGNORE <<EOM
# ignore logs
logs/

# tls certs
letsencrypt/
acme/
ocsp/

EOM

read -r -d '' INST_DOCKERFILE <<"EOM"

ENV OPENSSL_VERSION 1.0.2e-r0

RUN apk add --no-cache \
bash \
ca-certificates \
curl \
drill \
git \
openssh-client \
sudo \
"openssl>=${OPENSSL_VERSION}"

# TODO add bind-tools to generate dnssec-keys

# Install hugo
ENV URL="https://github.com/spf13/hugo/releases/download/v0.17/hugo_0.17_Linux-64bit.tar.gz"
RUN \
curl -sSLo /tmp/hugo.tgz ${URL} \
&& tar xzf /tmp/hugo.tgz -C /tmp hugo_0.17_linux_amd64/hugo_0.17_linux_amd64 \
&& mv /tmp/hugo_0.17_linux_amd64/hugo_0.17_linux_amd64 /usr/local/bin/hugo \
&& rm -rf /tmp/*

# Install caddy
ARG CURL_FEATURES
ENV CURL_FEATURES ${CURL_FEATURES:-"DNS,cors,filemanager,git,hugo,ipfilter,jwt,locale,minify,ratelimit,realip,upload"}
RUN curl -fsSL https://getcaddy.com | bash -s ${CURL_FEATURES}

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
EXPOSE 53 53/udp 80 443 2015
ENTRYPOINT ["caddy"]

EOM


read -r -d '' INST_CADDYFILE <<EOM
http://start.domain.tld:80 http://:80 http://www.domain.tld:80 http://domain.tld:80 {
  tls off
# add this if you like to enable tls
#  tls ACME_MAIL
  log / /data/logs/caddy.log "[startpage] - {when} - {remote} - {proto} {method} {path} - {status} {size}"
  root /data/www
  minify

  redir /ip /ip.txt
  mime .txt text/plain
  templates /ip .txt

}#END_start


EOM

read -r -d '' INST_COMPOSE <<EOM
version: "2"
networks:
  backend:
    external:
      name: CADDYNET

services:
  caddy:
    image: CADDY_IMAGENAME
    restart: on-failure:5
    cap_add:
      - NET_BIND_SERVICE
    user: root
    networks:
    - backend
    ports:
      - "80:80"
      - "443:443"
#    - "2015:2015"
#      - "53:53"
#      - "53:53/udp"
#    command: -http2=false -conf /data/conf/caddyfile
    command: -type http -port 80 -http2=false -conf /data/conf/caddyfile
#    command: -type dns -port 53 -conf /data/conf/corefile
    read_only: true
    working_dir: /data
    environment:
      - CADDYPATH=/data
    volumes:
      - ./caddy:/data:rw

EOM
