## Caddy in a Docker Container
### running as reverse proxy for various services



*NOTE: The caddy config file name must be the same like the folder name in the services directory and in the docker-compose file for the main container*
 - caddy config file
 - services folder
 - docker-compose main container

#### Dependencies
 - docker >= 1.10.0
 - docker-compose >= 1.7.0
 - jq
 - multitail 

#### 1. create caddy vhost config in `caddy/conf/available/` like

```
dokuwiki.domain.tld:80 {
  tls off
  log / /root/.caddy/logs/dokuwiki.log "{proto} Request: {method} {path} ... {scheme} {host} {remote}"
  proxy / http://dokuwiki:80/ {
    proxy_header Host {host}
    proxy_header X-Real-IP {remote}
    proxy_header X-Forwarded-Proto {scheme}
  }
}

```

#### 2. create service config in `services/` like

folder structure example
```
services/dokuwiki/
├── docker
│   └── Dockerfile
└── docker-compose.yml

```

`docker-compose.yml` example
```
version: '2'
networks:
  backend:
    external:
      name: caddy_backend

services:
  dokuwiki:
    networks:
      - backend
    expose:
      - 80
    build:
      context: ./docker/
      dockerfile: Dockerfile
    # volumes:
    #   - ./conf/:/dokuwiki-conf/
    #   - ./data/:/dokuwiki-data/
```

### control command:
```
usage:

  caddyctl start              Start the Caddy server.

  caddyctl stop               Stop the Caddy server.

  caddyctl restart            Restart the Caddy server. (recreate caddy container)

  caddyctl reload             Reload the Caddy server config (restart caddy container).

  caddyctl caddylog           Log from the Caddy server.

  caddyctl vhostlog           Log from the Caddy server vhosts.

  caddyctl logs <service>     Logs of a service. (run docker-compose logs -f)

  caddyctl enable  <service>  Enable a service. (add settings to caddy; run docker-compose up)

  caddyctl disable <service>  Disable a service. (remove settings from caddy; run docker-compose down)

  caddyctl new <service>      Create new service template. (caddy conf and docker-compose.yml)

  caddyctl prepare <service>  Build / Pull Docker Image(s) of a service. (run docker-compose build and docker-compose pull)

  caddyctl ps                 Get status of all connected Container.

  caddyctl list               List all Services (Docker Applications).

  caddyctl index              Create index page for active Services available at '/caddy.html'.

  caddyctl sethome <fqdn>     Set FQDN for all vhosts. (e.g.: <domain.tld>)

  caddyctl cleanup            Remove all dangling Docker resources.

```
