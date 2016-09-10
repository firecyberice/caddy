#!/bin/bash
# Manage Caddyserver as frontend proxy for Docker container
# Andreas Eiermann
#
# MIT License

# 1

VERSION="0.7.0"

if [ -f ./config.sh ]; then
    . ./config.sh
fi

: ${CADDY_DIR:="caddy"}
: ${SERVICES_DIR:="services"}
: ${MAIL:="noreply@domain.tld"}
: ${FQDN:="domain.tld"}


[ ${PROJECT:-} ] && PROJECT="-p $PROJECT"
: ${NETWORK:="caddy_backend"}
: ${CADDY_IMAGENAME:="fciserver/caddy"}
