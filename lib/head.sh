#!/bin/bash
# Manage Caddyserver as frontend proxy for Docker container
# Andreas Eiermann
#
# MIT License

# 1

VERSION="0.5.0"

if [ -f ./config.sh ]; then
    . ./config.sh
fi

[ ${PROJECT:-} ] && PROJECT="-p $PROJECT"
: ${NETWORK:="caddy_backend"}
: ${CADDY_DIR:="caddy"}
: ${SERVICES_DIR:="services"}
