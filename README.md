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

  caddyctl list               List all Services (Docker Applications).

  caddyctl enable  <service>  Enable a service. (add settings to caddy; run docker-compose up)

  caddyctl disable <service>  Disable a service. (remove settings from caddy; run docker-compose down)

  caddyctl build <service>    Build Docker Image of a service. (run docker-compose build)

  caddyctl sethome <fqdn>     Set FQDN for all vhosts. (e.g.: <domain.tld>)

  caddyctl index              Create index page for active Services available at '/caddy.html'.

  caddyctl cleanup            Remove all dangling Docker resources.

```
