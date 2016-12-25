# 2

function core_version(){
  echo "Caddy Manager Version: ${VERSION}"
}

function core_start(){
  docker network create --driver=bridge "${NETWORK}"

  echo "create and start frontend proxy"
  grep "name: ${NETWORK}" docker-compose.yml
  docker-compose "${PROJECT}" up -d
}

function core_stop(){
  echo "stop and remove frontend proxy"
  docker-compose "${PROJECT}" down --rmi local

  docker network rm "${NETWORK}"
}

function core_restart(){
  echo "restart frontend proxy"
  docker-compose "${PROJECT}" down --volumes
  docker-compose "${PROJECT}" up -d
}

function core_reload(){
  echo "reload frontend proxy"
  docker-compose "${PROJECT}" restart
}

function core_up(){
  for j in ${CADDY_DIR}/conf/enabled/*; do
    local sname="$(basename $j)"
    test -f "${SERVICES_DIR}/${sname}/docker-compose.yml" && \
    docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${sname}/docker-compose.yml" up -d
  done
}

function core_down(){
  for j in ${CADDY_DIR}/conf/enabled/*; do
    local sname="$(basename $j)"
    test -f "${SERVICES_DIR}/${sname}/docker-compose.yml" && \
    docker-compose "${PROJECT}" -f "${SERVICES_DIR}/${sname}/docker-compose.yml" down
  done
  echo "archive logfiles"
  local DATE=$(date +"%Y%m%d-%H%M%S")
  tar czf "${CADDY_DIR}/logs_${DATE}.tar.gz" "${CADDY_DIR}/logs"
  rm -rf "${CADDY_DIR}/logs/*"
}

function core_list(){
  echo -e "\n\e[34mdocker apps\e[39m"
  ls -1 "${SERVICES_DIR}/"

  find "${CADDY_DIR}/conf/" -type f -name '*~' -delete
  echo -e "\n\e[34mavailable\e[39m"
  ls -1 "${CADDY_DIR}/conf/available/"

  echo -e "\n\e[34menabled\e[39m"
  ls -1 "${CADDY_DIR}/conf/enabled/"
  echo -e "\n\n"
}

function core_ps(){
  cmd='docker ps --format="table{{.ID}}\t{{.Image}}\t{{.RunningFor}}\t{{.Status}}\t{{.Names}}" -a '
  filterlist="${CADDY_DIR}/conf/enabled/*"
  eval ${cmd} | head -n 1
  if [[ -z ${PROJECT} ]]; then
    eval "${cmd}" | grep "caddy"
    for item in ${filterlist}; do
      eval "${cmd}" | grep "$(basename "${item}")_"
    done
  else
    eval "${cmd}" | grep "${PROJECT##-p }"
  fi
}

function core_cleanup(){
  echo "remove dangling images"
  docker rmi $(docker images --quiet --filter dangling=true)

  echo "remove dangling volumes"
  docker volume rm $(docker volume ls --quiet --filter dangling=true)
}

function core_caddylog(){
  docker-compose "${PROJECT}" logs -f
}
