# 3

function srv_prepare(){
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" build
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" pull --ignore-pull-failures
}

function srv_log(){
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" logs -f
}

function srv_enable(){
  ln -sr "${CADDY_DIR}/conf/available/${SERVICE}" "${CADDY_DIR}/conf/enabled/"
  # add import if files are available in enabled/ and import does not exist
  [[ $(ls -A "${CADDY_DIR}/conf/enabled/") ]] && \
  (grep -q "import /data/conf/enabled/*" "${CADDY_DIR}/conf/caddyfile" || \
  echo "import /data/conf/enabled/*" >> "${CADDY_DIR}/conf/caddyfile")

  docker-compose ${PROJECT} restart
  test -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" && \
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" up -d
}

function srv_disable(){
  rm -f "${CADDY_DIR}/conf/enabled/${SERVICE}"
  # remove import if NO files are available in enabled/ and import does exist
  [[ $(ls -A "caddy/conf/enabled/") ]] || sed -i -e '\|import /data/conf/enabled/\*|d' "caddy/conf/caddyfile"
  docker-compose ${PROJECT} restart
  test -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" && \
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" down
}

function srv_pack(){
  srv_check
  echo "pack ${SERVICE}"
  mkdir -p packages/

  echo "create temp folder"
  TEMP_DIR=$(mktemp -d /tmp/packcaddyservice.XXXXXX)
  mkdir -p "${TEMP_DIR}/services/${SERVICE}" "${TEMP_DIR}/caddy/conf/available"

  echo "get caddy config"
  cp -r "${CADDY_DIR}/conf/available/${SERVICE}" "${TEMP_DIR}/caddy/conf/available/"
  echo "get docker-compose.yml"
  cp -r "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" "${TEMP_DIR}/services/${SERVICE}/"
  echo "get Dockerfiles in docker folder"
  cp -r "${SERVICES_DIR}/${SERVICE}/docker" "${TEMP_DIR}/services/${SERVICE}/"

  tar czf "packages/${SERVICE}.tar.gz" -C "${TEMP_DIR}/" .
}

function srv_uninstall(){
  echo "disable service before removing it"
  srv_disable

  echo "removing ${SERVICE}"
  rm -ri "${CADDY_DIR}/conf/available/${SERVICE}"
  rm -ri "${SERVICES_DIR}/${SERVICE}/docker-compose.yml"
  rm -ri "${SERVICES_DIR}/${SERVICE}/docker"
  if [[ ! "$(ls -A "${SERVICES_DIR}/${SERVICE}")" ]]; then
    rm -ri "${SERVICES_DIR}/${SERVICE}"
  fi
}

function srv_install(){
  echo "unpack caddy config"
  tar --strip-components 2 -xzf "${SERVICE}.tar.gz" -C "${CADDY_DIR}" caddy/
  echo "unpack service"
  tar --strip-components 2 -xzf "${SERVICE}.tar.gz" -C "${SERVICES_DIR}" services/
}

function srv_check(){
  echo "check docker-compose.yml of ${SERVICE}"
  docker-compose -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" config --quiet
  return $?
}

function srv_new(){
  mkdir -p "${SERVICES_DIR}/${SERVICE}/docker/"
  echo "create caddy vhost"
  echo -e "${NEW_CADDYFILE}" > "${CADDY_DIR}/conf/available/${SERVICE}"
  sed -i -e "s|SERVICE|${SERVICE}|g" "${CADDY_DIR}/conf/available/${SERVICE}"
  sed -i -e "s|domain\.tld|${FQDN}|g" "${CADDY_DIR}/conf/available/${SERVICE}"
  sed -i -e "s|ACME_MAIL|${ACME_MAIL}|g" "${CADDY_DIR}/conf/available/${SERVICE}"
  echo "create docker-compose.yml"
  echo -e "${NEW_COMPOSE}" > "${SERVICES_DIR}/${SERVICE}/docker-compose.yml"
  sed -i -e "s|SERVICE|${SERVICE}|g" "${SERVICES_DIR}/${SERVICE}/docker-compose.yml"
  sed -i -e "s|CADDYNET|${CADDYNET}|g" "${SERVICES_DIR}/${SERVICE}/docker-compose.yml"
  echo "create example Dockerfile"
  echo -e "${NEW_DOCKERFILE}" > "${SERVICES_DIR}/${SERVICE}/docker/Dockerfile"
  echo "Hello ${SERVICE}" > "${SERVICES_DIR}/${SERVICE}/docker/index.html"
}
