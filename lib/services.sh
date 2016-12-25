# 3

function srv_prepare(){
  docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" build
  docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" pull --ignore-pull-failures
}

function srv_log(){
  docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" logs -f
}

function srv_enable(){
  ln -sr "${CADDY_DIR}/conf/available/${SERVICE}" "${CADDY_DIR}/conf/enabled/"
  # add import if files are available in enabled/ and import does not exist
  [[ $(ls -A "${CADDY_DIR}/conf/enabled/") ]] && \
  (grep -q "import /data/conf/enabled/*" "${CADDY_DIR}/conf/caddyfile" || \
  echo "import /data/conf/enabled/*" >> "${CADDY_DIR}/conf/caddyfile")

  docker-compose "${PROJECT}" restart
  test -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" && \
  docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" up -d
}

function srv_disable(){
  rm -f "${CADDY_DIR}/conf/enabled/${SERVICE}"
  # remove import if NO files are available in enabled/ and import does exist
  [[ $(ls -A "caddy/conf/enabled/") ]] || sed -i -e '\|import /data/conf/enabled/\*|d' "caddy/conf/caddyfile"
  docker-compose "${PROJECT}" restart
  test -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" && \
  docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${SERVICE}/docker-compose.yml" down
}
