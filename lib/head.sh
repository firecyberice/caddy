#!/bin/bash
# 1

CADDY_DIR="caddy"
SERVICES_DIR="services"
STARTPAGE_DIR="caddy/www"
VERSION="0.2.0"

if [ -f ./config.sh ]; then
    . ./config.sh
fi
PROJECT="-p ${PROJECT:-'caddymanager'}"
: ${NETWORK:-"caddy_backend"}
