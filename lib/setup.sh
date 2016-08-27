# 6

function set_index(){
  local newjson=""
  find ${CADDY_DIR}/conf/enabled -type f -name '*~' -delete
  for j in ${CADDY_DIR}/conf/enabled/*; do
    if [[ -z ${newjson} ]]; then
      newjson="["
    else
      newjson=${newjson}","
    fi
    i=$(basename $j)
    local link=$(head -n 1 ${CADDY_DIR}/conf/enabled/$i | cut -d' ' -f1)
    local example="{\"name\": \"$i\",\"link\": \"http://$link\",\"button\": \"btn-primary\",\"image\": \"empty\"}"
    newjson=${newjson}${example}
  done
  newjson=${newjson}"]"

  echo ${newjson} | jq '.' > "${STARTPAGE_DIR}/caddy.json"
  echo -e "Index created\nPlease open \e[34m'/caddy.html'\e[39m in your browser."
}

function set_home(){
  grep -rn "domain.tld" "${CADDY_DIR}/conf"
  if [[ -n "${SERVICE}" ]]; then
    find "${CADDY_DIR}/conf/available" -type f -exec sed -i -e "s/\.domain\.tld/\.${SERVICE}/g" {} \;
    sed -i -e "s/\.domain\.tld/\.${SERVICE}/g" ${CADDY_DIR}/conf/caddyfile
    sed -i -e "s/\.domain\.tld/\.${SERVICE}/g" ${CADDY_DIR}/conf/plugins
  fi
}

function set_mail(){
  grep -rn "noreply@domain.tld" "${CADDY_DIR}/conf"
  if [[ -n "${SERVICE}" ]]; then
    find "${CADDY_DIR}/conf/available" -type f -exec sed -i -e "s/noreply@domain\.tld/${SERVICE}/g" {} \;
    sed -i -e "s/noreply@domain\.tld/${SERVICE}/g" ${CADDY_DIR}/conf/caddyfile
    sed -i -e "s/noreply@domain\.tld/${SERVICE}/g" ${CADDY_DIR}/conf/plugins
  fi
}

function __evaluate_result(){
  local returnvalue="${1}"
  local message="${2}"
  if [ "$returnvalue" -eq 0 ]; then
#    echo -e "\e[32m  [PASS] ${message}\e[0m"
    echo -n ""
  else
    echo -e "\e[31m  [FAIL] ${message}\e[0m"
    ERROR=1
  fi
}

function __check_if_program_exists(){
  cmd="${1}"
  command -v $cmd >/dev/null 2>&1
  __evaluate_result $? "$cmd is installed"
}

function __test_requirements(){
  prog="${1}"
  ERROR=0
  __check_if_program_exists "${prog}"
  if [[ $ERROR -gt 0 ]]; then
    exit 1
  fi
}

function set_newservice(){
  mkdir -p ${SERVICES_DIR}/${SERVICE}/docker/
  echo "create caddy vhost"
  echo -e "$NEW_CADDYFILE" > ${CADDY_DIR}/conf/available/${SERVICE}
  sed -i -e "s|SERVICE|$SERVICE|g" ${CADDY_DIR}/conf/available/${SERVICE}
  echo "create docker-compose.yml"
  echo -e "$NEW_COMPOSE" > ${SERVICES_DIR}/${SERVICE}/docker-compose.yml
  sed -i -e "s|SERVICE|$SERVICE|g" ${SERVICES_DIR}/${SERVICE}/docker-compose.yml
  echo "create example Dockerfile"
  echo -e "$NEW_DOCKERFILE" > ${SERVICES_DIR}/${SERVICE}/docker/Dockerfile
  echo "Hello ${SERVICE}" > ${SERVICES_DIR}/${SERVICE}/docker/index.html
}

function set_setup(){
  mkdir -p ${CADDY_DIR}/{conf/available,conf/enabled,logs,www} services
  echo -e "$INST_GITIGNORE" > ${CADDY_DIR}/conf/.gitignore
  echo "create caddyfile"
  touch ${CADDY_DIR}/conf/enabled/.empty
  echo -e "$INST_CADDYFILE" > ${CADDY_DIR}/conf/caddyfile
  echo "create docker-compose.yml for caddy"
  echo -e "$INST_COMPOSE" > docker-compose.yml
  echo "append manager to .gitignore"
  echo "manager" >> .gitignore
}

function selectimage(){
  local ARCHITECTURE="${1}"
  local BASEIMAGE
  case "${ARCHITECTURE}" in
      arm*|aarch64)
          BASEIMAGE=armhf/alpine:3.4
          ;;
      amd64|x86_64)
          BASEIMAGE=alpine:3.4
          ;;
      * )
      echo "Your architecture is not supported."
      ;;
  esac
  echo "$BASEIMAGE"
}

function selectcaddy(){
  local ARCHITECTURE="${1}"
  local BASEIMAGE
  case "${ARCHITECTURE}" in
      arm*|aarch64)
          CADDYARCH=arm
          ;;
      amd64|x86_64)
          CADDYARCH=amd64
          ;;
      * )
      echo "Your architecture is not supported."
      ;;
  esac
  echo "$CADDYARCH"
}
function set_docker(){
  local ARCHITECTURE=$(uname -m)
  local CADDY_ARCHITECTURE=$(selectcaddy "${ARCHITECTURE}")
  local BASEIMAGE=$(selectimage "${ARCHITECTURE}")
  echo -e "FROM ${BASEIMAGE}\n\n${INST_DOCKERFILE}" | docker build --build-arg ARCH="${CADDY_ARCHITECTURE}" -t firecyberice/caddy:frontend -
}
