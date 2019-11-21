FROM alpine/git

LABEL "com.github.actions.name"="Generate YAML file"
LABEL "com.github.actions.description"="Generate app.yml file with Github secrets on the fly"
LABEL "com.github.actions.icon"="corner-up-left"
LABEL "com.github.actions.color"="green"

LABEL "repository"="http://github.com/loyalguru/actions/generate_yaml"
LABEL "homepage"="http://github.com/loyalguru/actions/generate_yaml"
LABEL "maintainer"="Andrés D. Molins <adiaz@loyal.guru>"

RUN	apk add --no-cache \
	bash \
	ca-certificates \
	curl \
	curl-dev \
	jq \
	coreutils

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
