# 5

read -r -d '' NEW_CADDYFILE <<EOM
SERVICE.domain.tld:80 {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
  log / /data/logs/services.log "[SERVICE] - {when} - {remote} - {proto} {method} - {status} {size}"
  proxy / http://SERVICE:80/ {
    transparent
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
  SERVICE:
    networks:
      - backend
    hostname: SERVICE.domain.tld
    restart: on-failure:5
    expose:
      - 80
    image: SERVICE
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
