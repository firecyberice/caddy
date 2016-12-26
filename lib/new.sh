# 5

read -r -d '' NEW_CADDYFILE <<EOM
http://SERVICE.domain.tld:80 {
  tls off
# add this if you like to enable tls
#  tls ACME_MAIL
  log / /data/logs/services.log "[SERVICE] - {when} - {remote} - {proto} {method} {path} - {status} {size}"
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
      name: CADDYNET

services:
  SERVICE:
    networks:
      - backend
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
