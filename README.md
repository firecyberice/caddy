[![CircleCI](https://circleci.com/gh/firecyberice/caddy.svg?style=svg)](https://circleci.com/gh/firecyberice/caddy)

# Caddy reverse Proxy for Docker (crpd)

## get general info and help
```
./manager version
./manager
```

## initial setup

```
./manager config
./manager setup
./manager setvars
./manager build
```

- `./manager config`             Create example config file for this tool.
- `./manager setup`              Create config folders.
- `./manager setvars`            Set FQDN for all vhosts to ${FQDN}. (e.g.: <domain.tld>)
                            Set email address to ${ACME_MAIL} for tls with letsencrypt.
                            Replace NETWORK in all docker-compose.yml files with ${NETWORK}.
- `./manager build`              Build caddy Docker image.



## service management

- `./manager start`              Start the Caddy server.
- `./manager stop`               Stop the Caddy server.
- `./manager up`                 Create and start all service container
- `./manager down`               Stop and remove all service container
- `./manager enable  <service>`  Enable a service. (add settings to caddy; run docker-compose up)
- `./manager disable <service>`  Disable a service. (remove settings from caddy; run docker-compose down)

- `./manager new <service>`      Create new service template. (caddy conf and docker-compose.yml)
- `./manager prepare <service>`  Build / Pull Docker Image(s) of a service. (run docker-compose build and docker-compose pull)
- `./manager logs <service>`     Logs of a service. (run docker-compose logs -f)


## caddy management

- `./manager restart`            Restart the Caddy server. (recreate caddy container)
- `./manager reload`             Reload the Caddy server config (restart caddy container).
- `./manager caddylog`           Log from the Caddy server.


## general tools / misc
- `./manager list`               List all Services (Docker Applications).
- `./manager ps`                 Get status of all connected Container.
- `./manager cleanup`           Remove all dangling Docker resources.
- `./manager index`              Create index page for active Services available at '/caddy.html'.
- `./manager version`            Display Version.
- `./manager plugins`            Add examples for caddy plugins like git hugo markdown to startpage.


## Build with circleci

#### These tests generate false positives `-->` ignoring them

- SC2046: Quote this to prevent word splitting
- SC2034: ... appears unused. Verify it or export it
- SC2086: Double quote to prevent globbing and word splitting

```
docker build --rm=false -t circleci/shellcheck .
docker run -it -v $(pwd)/lib:/data circleci/shellcheck -c "shellcheck -e SC2046 -e 2086 -e SC2034 *"

docker run -it -v $(pwd):/data circleci/shellcheck -c "./selfextractor_build.sh"
docker run -it -v $(pwd)/dist:/data circleci/shellcheck -c "shellcheck -e SC2046 -SC2086 manager"
```
