FROM alpine/git

LABEL "com.github.actions.name"="Notify deployment"
LABEL "com.github.actions.description"="Notify deployment in chat and send Datadog event"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/notify_deploy"
LABEL "homepage"="http://github.com/loyalguru/actions/notify_deploy"
LABEL "maintainer"="Platform Team <platform@loyal.guru>"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils

WORKDIR /app

ENV ACTION_PATH "/"

COPY *.sh /

RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
