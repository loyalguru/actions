FROM node:16-alpine

LABEL "com.github.actions.name"="Build JS app"
LABEL "com.github.actions.description"="Install NPM dependencies of a Javascript application"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/js_build"
LABEL "homepage"="http://github.com/loyalguru/actions/js_build"
LABEL "maintainer"="Dario Castañé <dcastane@loyal.guru> / Jose Osorno <josorno@loyal.guru>"

RUN	apk add --no-cache --virtual .build-deps  \
    make gcc g++ \
    git \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils

RUN npm config set unsafe-perm true

RUN npm install -g @angular/cli@15.1.4

ADD chat.sh /chat.sh
RUN chmod +x /chat.sh
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
