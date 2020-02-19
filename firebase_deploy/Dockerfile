FROM node:10.19.0-alpine

LABEL "com.github.actions.name"="Deploy to Firebase"
LABEL "com.github.actions.description"="Deploy a Javascript application to firebase"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/firebase_deploy"
LABEL "homepage"="http://github.com/loyalguru/actions/firebase_deploy"
LABEL "maintainer"="Andrés D. Molins <adiaz@loyal.guru> / Jose Osorno <josorno@loyal.guru>"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils

RUN npm config set unsafe-perm true

RUN npm install -g firebase-tools

ADD chat.sh /chat.sh
RUN chmod +x /chat.sh
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
