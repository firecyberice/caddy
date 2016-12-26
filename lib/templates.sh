# 4

read -r -d '' INST_GITIGNORE <<EOM
# ignore logs
logs/

# tls certs
letsencrypt/
acme/
ocsp/

EOM

read -r -d '' INST_CONFIGFILE <<"EOM"
#
# configfile for caddy manager
#

#CADDY_DIR=caddy
#SERVICES_DIR=services
#PROJECT=demo

# Network for services to connect to caddy
#CADDYNET=CADDYNET
# Mail address for Let's Encrypt
#ACME_MAIL=ACME_MAIL
# Default server hostname for generating subdomains
#FQDN=domain.tld

# Settings for the caddy Docker image
#CADDY_FEATURES='DNS,cors,filemanager,git,hugo,ipfilter,jwt,locale,minify,ratelimit,realip,upload'
#CADDY_IMAGENAME=fciserver/caddy

EOM

read -r -d '' INST_DOCKERFILE <<"EOM"

ENV OPENSSL_VERSION 1.0.2e-r0

RUN apk add --no-cache \
bash \
ca-certificates \
curl \
drill \
git \
openssh-client \
sudo \
"openssl>=${OPENSSL_VERSION}"

# TODO add bind-tools to generate dnssec-keys

# Install hugo
ENV URL="https://github.com/spf13/hugo/releases/download/v0.17/hugo_0.17_Linux-64bit.tar.gz"
RUN \
curl -sSLo /tmp/hugo.tgz ${URL} \
&& tar xzf /tmp/hugo.tgz -C /tmp hugo_0.17_linux_amd64/hugo_0.17_linux_amd64 \
&& mv /tmp/hugo_0.17_linux_amd64/hugo_0.17_linux_amd64 /usr/local/bin/hugo \
&& rm -rf /tmp/*

# Install caddy
ARG CURL_FEATURES
ENV CURL_FEATURES ${CURL_FEATURES:-"DNS,cors,filemanager,git,hugo,ipfilter,jwt,locale,minify,ratelimit,realip,upload"}
RUN curl -fsSL https://getcaddy.com | bash -s ${CURL_FEATURES}

# Fix to use git plugin
RUN mkdir /root/.ssh \
&& echo -e "\
StrictHostKeyChecking no\\n\
UserKnownHostsFile /dev/null\\n\
" > /root/.ssh/config

#RUN adduser -Du 1000 caddy \
#    && mkdir /home/caddy/.ssh \
#    && cp /root/.ssh/config /home/caddy/.ssh/config
#USER caddy
EXPOSE 53 53/udp 80 443 2015
ENTRYPOINT ["caddy"]

EOM

read -r -d '' INST_CADDYFILE <<EOM
http://start.domain.tld:80 http://:80 http://www.domain.tld:80 http://domain.tld:80 {
  tls off
# add this if you like to enable tls
#  tls ACME_MAIL
  log / /data/logs/caddy.log "[startpage] - {when} - {remote} - {proto} {method} {path} - {status} {size}"
  root /data/www
  minify

  redir /ip /ip.txt
  mime .txt text/plain
  templates /ip .txt

}#END_start

EOM
read -r -d '' INST_COMPOSE <<EOM
version: "2"
networks:
  backend:
    external:
      name: CADDYNET

services:
  caddy:
    image: CADDY_IMAGENAME
    restart: on-failure:5
    cap_add:
      - NET_BIND_SERVICE
    user: root
    networks:
    - backend
    ports:
      - "80:80"
      - "443:443"
#    - "2015:2015"
#      - "53:53"
#      - "53:53/udp"
#    command: -http2=false -conf /data/conf/caddyfile
    command: -type http -port 80 -http2=false -conf /data/conf/caddyfile
#    command: -type dns -port 53 -conf /data/conf/corefile
    read_only: true
    working_dir: /data
    environment:
      - CADDYPATH=/data
    volumes:
      - ./caddy:/data:rw

EOM

read -r -d '' NEW_CADDYFILE <<EOM
http://SERVICE.domain.tld:80 {
  tls off
# add this if you like to enable tls
#  tls ACME_MAIL
  log / /data/logs/services.log "[SERVICE] - {when} - {remote} - {proto} {method} {path} - {status} {size}"
  proxy / http://SERVICE:80/ {
    transparent
  }
}

EOM

read -r -d '' NEW_COMPOSE <<EOM
version: '2'
networks:
  backend:
    external:
      name: CADDYNET

services:
  SERVICE:
    networks:
      - backend
    restart: on-failure:5
    expose:
      - 80
    image: SERVICE
    build:
      context: ./docker/
      dockerfile: Dockerfile

EOM

read -r -d '' NEW_DOCKERFILE <<EOM
FROM busybox
#FROM armhf/busybox
WORKDIR /www
COPY index.html /www/index.html
EXPOSE 80
ENTRYPOINT ["httpd"]
CMD ["-f","-v","-p","80","-h", "/www"]

EOM

read -r -d '' PLUGIN_CADDYFILE <<EOM
http://start.domain.tld:80/file {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
  root /data/htdocs
  log / /data/logs/plugins.log "[browse] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  browse /
  #  protect using HTTP basic auth
  basicauth / admin password
}

http://start.domain.tld:80/filemanager {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
  root /data/htdocs/files
  log / /data/logs/plugins.log "[filemanager] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  filemanager {
    show /data/htdocs/files/
  }
  #  protect using HTTP basic auth
  basicauth / admin password
}

http://start.domain.tld:80/hugo {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
  root /data/htdocs/hugo/public
  log / /data/logs/plugins.log "[hugo] - {when} - {remote} - {proto} {method} {path} - {status} {size}"

  hugo /data/htdocs/hugo
  #  protect the admin area using HTTP basic auth
  basicauth /admin admin password
}

http://start.domain.tld:80/git {
  tls off
# add this if you like to enable tls
#  tls noreply@domain.tld
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

read -r -d '' WEB_MAINJS <<"EOM"
jQuery.fn.extend({
    linklist: function (kwargs) {
        var self = $(this);
        $.ajax({
            url: dataurl,
            async:true,
            contentType:"application/json",
            dataType: "json",
            success: function(data){
                $.each(data, function(key, attributes){
                 var my_link = (typeof attributes['link'] != 'undefined') ? attributes['link'] : "";
                 var my_button = (typeof attributes['button'] != 'undefined') ? attributes['button'] : "";
                 var my_name = (typeof attributes['name'] != 'undefined') ? attributes['name'] : "";
                 var my_image = ((typeof attributes['image'] != 'undefined') && (attributes['image'] == "empty")) ? my_name : attributes['image'];

                 var new_div = $("<li>");
                        var new_anchor = $("<a>");
                        $(new_anchor).attr("href", my_link);
                        $(new_anchor).addClass("btn");
                        $(new_anchor).addClass(my_button);
                        $(new_anchor).attr("style", "height:150px");
                            if ((typeof my_image != 'undefined') && (my_image != "empty")) {
                                var new_content = $("<span>");
                                if (my_image != my_name) {
                                     $(new_anchor).html(my_name);
                                     new_content = $("<img>");
                                     $(new_content).addClass("img-responsive");
                                     $(new_content).attr("src", my_image);
                                }else{
                                    var new_br = $("<br>");
                                    $(new_br).appendTo(new_anchor);
                                    new_content = $("<div>");
                                    $(new_content).attr("style", "width:100px;height:100px");
                                    $(new_content).html(my_name);
                                }
                                $(new_content).appendTo(new_anchor);
                            }
                        $(new_anchor).appendTo(new_div);
                        console.log(new_div);
                    $(new_div).appendTo(self);
                });
            }
        });
    }
});

/*
jQuery.fn.extend({
    impress: function (kwargs) {
        var self = $(this);
        $.ajax({
            url: "vcf/api.php",
            async:true,
            contentType:"text/html",
            dataType: "html",
            success: function(data){
                $(self).html(data);
            }
        });
    }
});
*/
$(document).ready(function(){
    $("#content").linklist();
//    $("#impressum").impress();
});

EOM

read -r -d '' WEB_HTML <<"EOM"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>Landingpage</title>

    <!-- Bootstrap -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv.min.js"></script>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
    <style>
         ul {
             list-style-type: none;
         }
         li {
             float:left;
             padding:20px;
         }
    </style>
    <script>
      var dataurl="DATASOURCE"
    </script>
  </head>
  <body>
<div class="container">

    <div class="jumbotron">
         <h1>landingpage</h1>
         <p class="lead"></p>
    </div>
    <div class="container">

       <ul id="content">
         <li><a style="height:150px" class="btn btn-info" href="FIRSTLINK"><br><div style="width:100px;height:100px">FIRSTTITLE</div></a></li>

       </ul>
</div>

</div><!--/.container-->
   <hr>

   <footer>
     <p>&copy; 2015 Company, Inc.</p>
     <div id="impressum"></div>
   </footer>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
    <!--<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.0/jquery.min.js"></script>-->
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <script src="main.js"></script>
  </body>
</html>

EOM
