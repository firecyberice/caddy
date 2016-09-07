# 8

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

  echo ${newjson} | jq '.' > "${CADDY_DIR}/www/caddy.json"
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

function set_caddyplugins(){
  mkdir -p ${CADDY_DIR}/htdocs/{files,hugo/public,git/key,git/www}
  echo "create caddyfile"
  echo -e "$PLUGIN_CADDYFILE" > ${CADDY_DIR}/conf/plugins
  set -x
  (echo -e "import  /data/conf/plugins" >> ${CADDY_DIR}/conf/caddyfile)
  set +x
  echo -e "$PLUGIN_WEBLINKS" > ${CADDY_DIR}/www/index.json
  echo "generate RSA ssh key"
  ssh-keygen -q -N '' -t rsa -f ${CADDY_DIR}/htdocs/git/key/id_rsa
  echo -e "\e[31mCopy and paste this key as deploy key into git:\e[0m\n"
  cat ${CADDY_DIR}/htdocs/git/key/id_rsa.pub
  echo -e "\n\e[31mRegister webhook in your git server.\e[0m"
  echo "Pointing to: <start.domain.tld/git/webhook> with your"
  echo "hook secret (default: webhook-secret) from the caddyfile"
  echo -e "\nDefault credentials for caddy basicauth: \e[31madmin:password\e[0m\n"
}

function set_createwebsite(){
  echo "create startpage"
  local WWW_DIR="${CADDY_DIR}/www"
  mkdir -p  ${WWW_DIR}

  echo "create robots.txt"
  echo -e "User-agent: *\nDisallow: /" > ${WWW_DIR}/robots.txt
  echo -n "{{.IP}}" > ${WWW_DIR}/ip.txt

  echo "create main.js"
  echo -e "$WEB_MAINJS" > ${WWW_DIR}/main.js

  echo "create index.html"
  echo -e "$WEB_HTML" > ${WWW_DIR}/index.html
  sed -i -e 's|DATASOURCE|index.json|g' ${WWW_DIR}/index.html
  sed -i -e 's|FIRSTTITLE|caddy|g' ${WWW_DIR}/index.html
  sed -i -e 's|FIRSTLINK|caddy.html|g' ${WWW_DIR}/index.html

  echo "create caddy.html"
  echo -e "$WEB_HTML" > ${WWW_DIR}/caddy.html
  sed -i -e 's|DATASOURCE|caddy.json|g' ${WWW_DIR}/caddy.html
  sed -i -e 's|FIRSTTITLE|start|g' ${WWW_DIR}/caddy.html
  sed -i -e 's|FIRSTLINK|/|g' ${WWW_DIR}/caddy.html
}

function set_setup(){
  mkdir -p ${CADDY_DIR}/{conf/available,conf/enabled,logs} services
  echo -e "$INST_GITIGNORE" > ${CADDY_DIR}/.gitignore
  echo "create caddyfile"
#  touch ${CADDY_DIR}/conf/enabled/.empty
  echo -e "$INST_CADDYFILE" > ${CADDY_DIR}/conf/caddyfile
  echo "create docker-compose.yml for caddy"
  echo -e "$INST_COMPOSE" > docker-compose.yml
  echo "create config.sh for this manager"
  echo -e "\
# configfile for caddy manager\n\
#\n\
#CADDY_DIR=caddy\n\
#SERVICES_DIR=services\n\
#PROJECT=demo\n\
#NETWORK=caddynet"\
  > config.sh
  set_createwebsite
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

  echo -e "\nTag image with corresponding caddy version"
  local caddy_version=$(docker run --rm firecyberice/caddy:frontend --version | cut -d' ' -f2)
  docker tag firecyberice/caddy:frontend firecyberice/caddy:${caddy_version}
}
