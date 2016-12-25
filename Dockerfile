FROM debian:jessie

RUN apt-get update -qq && apt-get install -y \
    shellcheck

WORKDIR /data
EXPOSE 80
ENTRYPOINT ["/bin/bash"]
CMD [""]
