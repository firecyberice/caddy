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
  docker-compose ${PROJECT} restart caddy
  test -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" && \
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" up -d
}

function srv_disable(){
  rm -f "${CADDY_DIR}/conf/enabled/${SERVICE}"
  docker-compose ${PROJECT} restart caddy
  test -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" && \
  docker-compose ${PROJECT} -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" down -v
}

function srv_vhostlog(){
  local logdir="${CADDY_DIR}/logs/*"
  multitail $logdir
}
