FROM alpine/git

LABEL "com.github.actions.name"="Deploy heroku app"
LABEL "com.github.actions.description"="Deploys a heroku app"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/heroku_deploy"
LABEL "homepage"="http://github.com/loyalguru/actions/heroku_deploy"
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