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
