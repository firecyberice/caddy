FROM debian:jessie

RUN apt-get update -qq && apt-get install -y \
    shellcheck \
    tree

WORKDIR /data
EXPOSE 80
ENTRYPOINT ["/bin/bash"]
