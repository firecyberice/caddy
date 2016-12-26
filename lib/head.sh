#!/bin/bash
# Manage Caddyserver as frontend proxy for Docker container
# Andreas Eiermann
#
# MIT License

# 1

VERSION=THISVERSION

if [ -f ./config.sh ]; then
    . ./config.sh
fi

: "${CADDY_DIR:=caddy}"
: "${SERVICES_DIR:=services}"
: "${ACME_MAIL:=noreply@domain.tld}"
: "${FQDN:=domain.tld}"


[ "${PROJECT:-}" ] && PROJECT="-p $PROJECT"
: "${CADDYNET:=caddy_backend}"
: "${CADDY_IMAGENAME:=fciserver/caddy}"
[ "${CADDY_FEATURES:-}" ] && CADDY_FEATURES="--build-arg CURL_FEATURES=${CADDY_FEATURES}"
