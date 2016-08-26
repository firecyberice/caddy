# 4

read -r -d '' NEW_CADDYFILE <<EOM
${SERVICE}.${TLD}:80 {
  tls off
# add this if you like to enable tls
#  tls noreply@example.com
  log / /root/.caddy/logs/${SERVICE}.log "{proto} Request: {method} {path} ... {scheme} {host} {remote}"
  root /root/.caddy/startpage/
  errors {
    403 403.html # Forbidden
    404 404.html # Not Found
    500 500.html # Internal Server Error
    502 502.html # Bad Gateway
    503 503.html # Service Unavailable
    504 504.html # Gateway Time-out
  }
  proxy / http://${SERVICE}:80/ {
    proxy_header Host {host}
    proxy_header X-Real-IP {remote}
    proxy_header X-Forwarded-Proto {scheme}
  }
}

EOM


read -r -d '' NEW_COMPOSE <<EOM
version: '2'
networks:
  backend:
    external:
      name: ${NETWORK}

services:
  ${SERVICE}:
    networks:
      - backend
    hostname: ${SERVICE}.${TLD}
    restart: on-failure:5
    expose:
      - 80
    image: ${SERVICE}
    build:
      context: ./docker/
      dockerfile: Dockerfile

EOM

read -r -d '' NEW_DOCKERFILE <<EOM
FROM busybox
#FROM armhf/busybox
WORKDIR /www
COPY index.html /www/index.html
EXPOSE 80
ENTRYPOINT ["httpd"]
CMD ["-f","-v","-p","80","-h", "/www"]

EOM
