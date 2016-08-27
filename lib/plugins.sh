# 7

read -r -d '' PLUGIN_CADDYFILE <<EOM
start.domain.tld:80/file {
  tls off
  root /data/htdocs
  log / /data/logs/plugins.log "[browse] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  browse /
  #  protect using HTTP basic auth
  basicauth / admin password
}

start.domain.tld:80/filemanager {
  tls off
  root /data/htdocs/files
  log / /data/logs/plugins.log "[filemanager] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  filemanager {
    show /data/htdocs/files/
  }
  #  protect using HTTP basic auth
  basicauth / admin password
}

start.domain.tld:80/hugo {
  tls off
  root /data/htdocs/hugo/public
  log / /data/logs/plugins.log "[hugo] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  hugo /data/htdocs/hugo
  #  protect the admin area using HTTP basic auth
  basicauth /admin admin password
}

start.domain.tld:80/git {
  tls off
  root /data/htdocs/git/www
  log / /data/logs/plugins.log "[git] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  git {
#    repo      ssh://git@github.com:22/octocat/octocat.github.io.git
    repo      https://github.com/octocat/octocat.github.io.git
    branch    master
#    path      /data/htdocs/git/www
    #  ssh key for pulling private repos
#    key       /data/htdocs/git/key/id_rsa
    hook_type github
    #  Webhook url: http://start.domain.tld:80/git/webhook
    hook /webhook webhook-secret
    interval  86400
  }
}

EOM

read -r -d '' PLUGIN_WEBLINKS <<EOM
[
  {
    "name": "git",
    "link": "/git",
    "button": "btn-success",
    "image": "empty"
  },
  {
    "name": "hugo",
    "link": "/hugo",
    "button": "btn-success",
    "image": "empty"
  },
  {
    "name": "hugo admin",
    "link": "/hugo/admin",
    "button": "btn-danger",
    "image": "empty"
  },
  {
    "name": "filemanager",
    "link": "/filemanager",
    "button": "btn-danger",
    "image": "empty"
  },
  {
    "name": "filebrowser",
    "link": "/file",
    "button": "btn-warning",
    "image": "empty"
  }
]

EOM

function plugin_example(){
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
  echo -e "\n\n\e[31mDefault credentials for caddy basicauth: admin:password\e[0m"
}
