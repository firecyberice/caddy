# 8

function __evaluate_result(){
  local returnvalue="${1}"
  local message="${2}"
  if [ "${returnvalue}" -eq 0 ]; then
#    echo -e "\e[32m  [PASS] ${message}\e[0m"
    echo -n ""
  else
    echo -e "\e[31m  [FAIL] ${message}\e[0m"
    ERROR=1
  fi
}

function __check_if_program_exists(){
  local cmd="${1}"
  command -v "${cmd}" >/dev/null 2>&1
  __evaluate_result $? "${cmd} is installed"
}

function __test_requirements(){
  local prog="${1}"
  ERROR=0
  __check_if_program_exists "${prog}"
  if [[ ${ERROR} -gt 0 ]]; then
    echo "Please execute 'apt-get install -y ${prog}' to install ${prog}"
    exit 1
  fi
}

function __select_base_image(){
  case $(uname -m) in
    arm*|aarch64) BASEIMAGE=armhf/alpine:3.4 ;;
    amd64|x86_64) BASEIMAGE=alpine:3.4 ;;
    * ) echo "Your architecture is not supported." ;;
  esac
  echo "${BASEIMAGE}"
}

function __createwebsite(){
  echo "create startpage"
  local WWW_DIR="${CADDY_DIR}/www"
  mkdir -p  "${WWW_DIR}"

  echo "create robots.txt"
  echo -e "User-agent: *\nDisallow: /" > "${WWW_DIR}/robots.txt"
  echo -n "{{.IP}}" > "${WWW_DIR}/ip.txt"

  echo "create main.js"
  echo -e "${WEB_MAINJS}" > "${WWW_DIR}/main.js"

  echo "create index.html"
  echo -e "${WEB_HTML}" > "${WWW_DIR}/index.html"
  sed -i -e 's|DATASOURCE|index.json|g' "${WWW_DIR}/index.html"
  sed -i -e 's|FIRSTTITLE|caddy|g' "${WWW_DIR}/index.html"
  sed -i -e 's|FIRSTLINK|caddy.html|g' "${WWW_DIR}/index.html"

  echo "create caddy.html"
  echo -e "${WEB_HTML}" > "${WWW_DIR}/caddy.html"
  sed -i -e 's|DATASOURCE|caddy.json|g' "${WWW_DIR}/caddy.html"
  sed -i -e 's|FIRSTTITLE|start|g' "${WWW_DIR}/caddy.html"
  sed -i -e 's|FIRSTLINK|/|g' "${WWW_DIR}/caddy.html"
}

function set_index(){
  local newjson=""
  find "${CADDY_DIR}/conf/enabled" -type f -name '*~' -delete
  for j in ${CADDY_DIR}/conf/enabled/*; do
    if [[ -z ${newjson} ]]; then
      newjson="["
    else
      newjson=${newjson}","
    fi
    i=$(basename "$j")
    local link=$(head -n 1 "${CADDY_DIR}/conf/enabled/$i" | cut -d' ' -f1)
    if [[ "${link}" != http* ]]; then
      link="http://${link}"
    fi
    local example="{\"name\": \"$i\",\"link\": \"$link\",\"button\": \"btn-primary\",\"image\": \"empty\"}"
    newjson="${newjson}${example}"
  done
  newjson="${newjson}]"

  echo "${newjson}" | jq '.' > "${CADDY_DIR}/www/caddy.json"
  echo -e "Index created\nPlease open \e[34m'/caddy.html'\e[39m in your browser."
}

function set_newservice(){
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

function set_caddyplugins(){
  mkdir -p "${CADDY_DIR}/htdocs/{files,hugo/public,git/key,git/www}"
  echo "create caddyfile"
  echo -e "${PLUGIN_CADDYFILE}" > "${CADDY_DIR}/conf/plugins"
  set -x
  (grep -q "import  /data/conf/plugins" "${CADDY_DIR}/conf/caddyfile" || \
  echo "import  /data/conf/plugins" >> "${CADDY_DIR}/conf/caddyfile")
  set +x
  echo -e "${PLUGIN_WEBLINKS}" > "${CADDY_DIR}/www/index.json"
  echo "generate RSA ssh key"
  ssh-keygen -q -N '' -t rsa -f "${CADDY_DIR}/htdocs/git/key/id_rsa"
  echo -e "\e[31mCopy and paste this key as deploy key into git:\e[0m\n"
  cat "${CADDY_DIR}/htdocs/git/key/id_rsa.pub"
  echo -e "\n\e[31mRegister webhook in your git server.\e[0m"
  echo "Pointing to: <start.domain.tld/git/webhook> with your"
  echo "hook secret (default: webhook-secret) from the caddyfile"
  echo -e "\nDefault credentials for caddy basicauth: \e[31madmin:password\e[0m\n"

  set_variables
}

function set_variables(){
  grep -rn "domain.tld" "${CADDY_DIR}/conf"
  if [[ -n "${FQDN}" ]]; then
    echo "set FQDN in caddyfiles"
    find "${CADDY_DIR}/conf/available" -type f -exec sed -i -e "s/domain\.tld/${FQDN}/g" {} \;
    find "${CADDY_DIR}/conf" -mindepth 1 -maxdepth 1 -type f -exec sed -i -e "s/domain\.tld/${FQDN}/g" {} \;
  fi

  if [[ -n "${ACME_MAIL}" ]]; then
    echo "set MAIL for letsencrypt in caddyfiles"
    find "${CADDY_DIR}/conf/available" -type f -exec sed -i -e "s/ACME_MAIL/${ACME_MAIL}/g" {} \;
    find "${CADDY_DIR}/conf" -mindepth 1 -maxdepth 1 -type f -exec sed -i -e "s/ACME_MAIL/${ACME_MAIL}/g" {} \;
  fi

  if [[ -n "${CADDYNET}" ]]; then
    echo "set CADDYNET in docker-compose.yml files"
    find "${SERVICES_DIR}/" -mindepth 1 -maxdepth 2 -type f -name 'docker-compose.yml' -exec sed -i -e "s/CADDYNET/${CADDYNET}/g" {} \;
  fi
}

function set_simple_setup(){
  echo "create and edit config file"
  set_configfile
  editor config.sh
  echo "create folders and default website"
  set_setup
  echo "build caddy Docker image"
  set_docker
}

function set_setup(){
  mkdir -p "${CADDY_DIR}/{conf/available,conf/enabled,conf/zones,logs}" services
  echo -e "${INST_GITIGNORE}" > "${CADDY_DIR}/.gitignore"
  echo "create caddyfile"
#  touch ${CADDY_DIR}/conf/enabled/.empty
  echo -e "${INST_CADDYFILE}" > "${CADDY_DIR}/conf/caddyfile"
  echo "create docker-compose.yml for caddy"
  echo -e "${INST_COMPOSE}" > docker-compose.yml
  sed -i -e "s|CADDY_IMAGENAME|${CADDY_IMAGENAME}|g" docker-compose.yml
  sed -i -e "s/CADDYNET/${CADDYNET}/g" docker-compose.yml
  echo "create config.sh for this manager"

  set_variables
  __createwebsite
}

function set_configfile(){
[[ ! -f config.sh ]] && echo -e "\
# configfile for caddy manager\n\
#\n\
\n\
#CADDY_DIR=caddy\n\
#SERVICES_DIR=services\n\
#PROJECT=demo\n\n\
\n\
# Network for services to connect to caddy\n\
#CADDYNET=CADDYNET\n\
# Mail address for Let's Encrypt\n\
#ACME_MAIL=ACME_MAIL\n\
# Default server hostname for generating subdomains\n\
#FQDN=domain.tld\n\
\n\
#CADDY_FEATURES='DNS,cors,filemanager,git,hugo,ipfilter,jwt,locale,minify,ratelimit,realip,upload'\n\
#CADDY_IMAGENAME=fciserver/caddy\n"\
> config.sh
}

function set_docker(){
  local BASEIMAGE=$(__select_base_image)
  echo -e "FROM ${BASEIMAGE}\n\n${INST_DOCKERFILE}"
  echo -e "FROM ${BASEIMAGE}\n\n${INST_DOCKERFILE}" | docker build "${CADDY_FEATURES}" -t "${CADDY_IMAGENAME}" -

  echo -e "\nTag image with corresponding caddy version"
  local caddy_version=$(docker run --rm "${CADDY_IMAGENAME}:latest" --version | cut -d' ' -f2)
  docker tag "${CADDY_IMAGENAME}:latest" "${CADDY_IMAGENAME}:${caddy_version}"
}
