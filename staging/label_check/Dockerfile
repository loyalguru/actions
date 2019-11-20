FROM alpine/git

LABEL "com.github.actions.name"="Staging label check"
LABEL "com.github.actions.description"="Check if there is a staging label"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/staging/label_check"
LABEL "homepage"="http://github.com/loyalguru/actions/staging/label_check"
LABEL "maintainer"="Eric Ponce <tricokun@gmail.com>"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]