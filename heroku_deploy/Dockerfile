FROM node:alpine

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
	coreutils \
	git

RUN curl https://cli-assets.heroku.com/install.sh | sh

ADD chat.sh /chat.sh
RUN chmod +x /chat.sh
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
