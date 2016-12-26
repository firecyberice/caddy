# 9

function usage () {
cat << EOM
usage:

  ${0} start              Start the Caddy server.

  ${0} stop               Stop the Caddy server.

  ${0} up                 Create and start all service container

  ${0} down               Stop and remove all service container

  ${0} restart            Restart the Caddy server. (recreate caddy container)

  ${0} reload             Reload the Caddy server config (restart caddy container).

  ${0} list               List all Services (Docker Applications).

  ${0} ps                 Get status of all connected Container.

  ${0} cleanup            Remove all dangling Docker resources.

  ${0} caddylog           Log from the Caddy server.

  ${0} new <service>      Create new service template. (caddy conf and docker-compose.yml)

  ${0} prepare <service>  Build / Pull Docker Image(s) of a service. (run docker-compose build and docker-compose pull)

  ${0} enable  <service>  Enable a service. (add settings to caddy; run docker-compose up)

  ${0} disable <service>  Disable a service. (remove settings from caddy; run docker-compose down)

  ${0} logs <service>     Logs of a service. (run docker-compose logs -f)

  ${0} index              Create index page for active Services available at '/caddy.html'.

  ${0} setvars            Set FQDN for all vhosts to ${FQDN}. (e.g.: <domain.tld>)
                              Set email address to ${ACME_MAIL} for tls with letsencrypt.
                              Replace CADDYNET in all docker-compose.yml files with ${CADDYNET}.

  ${0} setup              Create config folders.

  ${0} config             Create example config file for this tool.

  ${0} build              Build caddy Docker image.

  ${0} version            Display Version.

  ${0} plugins            Add examples for caddy plugins like git hugo markdown to startpage.

EOM
}

function here_install(){
    core_version
    set_docker
    if [[ ! -f config.sh ]]; then
      set_setup
      set_caddyplugins
      set_configfile
      echo -e "Please configure config.sh and execute <$0 setvars> to complete setup."
      echo -e "Afterwards you can start the frontend with <$0 start>."
    else
      set_setup
      set_caddyplugins
      set_variables
      core_start
      __test_requirements jq
      set_index
      core_list
    fi
}

echo "Check requirements without exiting"
__check_if_program_exists jq

if [[ ${DEBUG} == "true" ]]; then
  echo "$@"
  eval "$@"
  exit 0
#  exec "$@"
elif [ $# -eq 1 ]; then
  case "${1}" in
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
    "install" )
      here_install
      ;;
    "config" )
      set_configfile
      ;;
    * )
      usage
      ;;
  esac
elif [ $# -eq 2 ]; then
SERVICE="${2}"
  case "${1}" in
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
