# 9

function usage () {
cat << EOM
usage:

  caddyctl start              Start the Caddy server.

  caddyctl stop               Stop the Caddy server.

  caddyctl up                 Create and start all service container

  caddyctl down               Stop and remove all service container

  caddyctl restart            Restart the Caddy server. (recreate caddy container)

  caddyctl reload             Reload the Caddy server config (restart caddy container).

  caddyctl list               List all Services (Docker Applications).

  caddyctl ps                 Get status of all connected Container.

  caddyctl cleanup            Remove all dangling Docker resources.

  caddyctl caddylog           Log from the Caddy server.

  caddyctl new <service>      Create new service template. (caddy conf and docker-compose.yml)

  caddyctl prepare <service>  Build / Pull Docker Image(s) of a service. (run docker-compose build and docker-compose pull)

  caddyctl enable  <service>  Enable a service. (add settings to caddy; run docker-compose up)

  caddyctl disable <service>  Disable a service. (remove settings from caddy; run docker-compose down)

  caddyctl logs <service>     Logs of a service. (run docker-compose logs -f)

  caddyctl index              Create index page for active Services available at '/caddy.html'.

  caddyctl setvars            Set FQDN for all vhosts to ${FQDN}. (e.g.: <domain.tld>)
                              Set email address to ${MAIL} for tls with letsencrypt.
                              Replace NETWORK in all docker-compose.yml files with ${NETWORK}.

  caddyctl setup              Create config folders.

  caddyctl build              Build caddy Docker image.

  caddyctl version            Display Version.

  caddyctl plugins            Add examples for caddy plugins like git hugo markdown to startpage.

EOM
}


echo "Check requirements without exiting"
__check_if_program_exists jq

if [[ $DEBUG == "true" ]]; then
  echo "$@"
  eval "$@"
  exit 0
#  exec "$@"
elif [ $# -eq 1 ]; then
  case "$1" in
    "start" )
      core_start
      ;;
    "stop" )
      core_stop
      ;;
    "restart" )
      core_restart
      ;;
    "reload" )
      core_reload
      ;;
    "up" )
      core_up
      ;;
    "down" )
      core_down
      ;;
    "caddylog" )
      core_caddylog
      ;;
    "cleanup" )
      core_cleanup
      ;;
    "ps" )
      core_ps
      ;;
    "list" )
      core_list
      ;;
    "index" )
      __test_requirements jq
      set_index
      ;;
    "setvars" )
      set_variables
      ;;
    "setup" )
      set_setup
      ;;
    "build" )
      set_docker
      ;;
    "version" )
      core_version
      ;;
    "plugins" )
      set_caddyplugins
      ;;
    * )
      usage
      ;;
  esac
elif [ $# -eq 2 ]; then
SERVICE="${2}"
  case "$1" in
    "enable" )
      srv_enable
      ;;
    "disable" )
      srv_disable
      ;;
    "prepare" )
      srv_prepare
      ;;
    "new" )
      set_newservice
      ;;
    "logs" )
      srv_log
      ;;
    * )
      usage
      ;;
  esac
else
  usage
fi
exit 0
