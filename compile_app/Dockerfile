FROM golang@sha256:7f5a49ae8af4b90d9df23577331e37c3461820fb502d8afd0453004f2a1150c3
# golang : 1.12.12-alpine3.10
# https://hub.docker.com/layers/golang/library/golang/1.12.12-alpine3.10/images/sha256-7f5a49ae8af4b90d9df23577331e37c3461820fb502d8afd0453004f2a1150c3

# Security settings taken from
# https://medium.com/@chemidy/create-the-smallest-and-secured-golang-docker-image-based-on-scratch-4752223b7324

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils

ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
