#!/bin/bash
# 1

CADDY_DIR="caddy"
SERVICES_DIR="services"
VERSION="0.5.0"

if [ -f ./config.sh ]; then
    . ./config.sh
fi
PROJECT="-p ${PROJECT:-'caddymanager'}"
: ${NETWORK:-"caddy_backend"}
