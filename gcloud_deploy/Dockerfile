FROM google/cloud-sdk:485.0.0-alpine

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils \
	make

ADD chat.sh /chat.sh
RUN chmod +x /chat.sh
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
