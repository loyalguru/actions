FROM alpine:git

LABEL "com.github.actions.name"="Deploy master check"
LABEL "com.github.actions.description"="Check if the branch is up to date with master"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/master_check"
LABEL "homepage"="http://github.com/loyalguru/actions/labelmaster_check_check"
LABEL "maintainer"="Eric Ponce <tricokun@gmail.com>"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	jq

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]