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
  fi
}

function set_mail(){
  TLD="$(head -n 1 "${CADDY_DIR}/conf/available/landingpage" |cut -d: -f1 |cut -d' ' -f1 |cut -d. -f2-)"
  grep -rn "noreply@domain.tld" "${CADDY_DIR}/conf"
  grep -rn "noreply@${TLD}" "${CADDY_DIR}/conf"
  if [[ -n "${SERVICE}" ]]; then
    find "${CADDY_DIR}/conf/available" -type f -exec sed -i -e "s/noreply@\.domain\.tld/${SERVICE}/g" -e "s/noreply@${TLD}/${SERVICE}/g" {} \;
  fi
}

function __evaluate_result(){
  local returnvalue="${1}"
  local message="${2}"
  if [ "$returnvalue" -eq 0 ]; then
    echo -e "\e[32m  [PASS] ${message}\e[0m"
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
  TLD="$(head -n 1 "${CADDY_DIR}/conf/caddyfile" |cut -d: -f1 |cut -d' ' -f1 |cut -d. -f2-)"
  mkdir -p ${SERVICES_DIR}/${SERVICE}/docker/
  echo "create caddy vhost"
  echo -e "$NEW_CADDYFILE" > ${CADDY_DIR}/conf/available/${SERVICE}
  echo "create docker-compose.yml"
  echo -e "$NEW_COMPOSE" > ${SERVICES_DIR}/${SERVICE}/docker-compose.yml
  echo "create example Dockerfile"
  echo -e "$NEW_DOCKERFILE" > ${SERVICES_DIR}/${SERVICE}/docker/Dockerfile
  echo "Hello ${SERVICE}" > ${SERVICES_DIR}/${SERVICE}/docker/index.html
}

function set_setup(){
  mkdir -p caddy/{conf/available,conf/enabled,startpage,landingpage,logs}
  echo -e "$INST_GITIGNORE" > caddy/conf/.GITIGNORE
  echo "create caddyfile"
  touch caddy/conf/enabled/.empty
  echo -e "$INST_CADDYFILE" > caddy/conf/caddyfile
  echo "create a simple startpage"
  echo "Default Website" > caddy/startpage/index.html
  echo "create docker-compose.yml for caddy"
  echo -e "$INST_COMPOSE" > docker-compose.yml
  echo "append manager to .gitignore"
  echo "manager" >> .gitignore
}

function set_docker(){
docker build -t firecyberice/caddy:demo - < "$(echo $INST_DOCKERFILE)"
}
