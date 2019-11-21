#!/bin/sh -l

set -e

main(){

  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")
  title=$(echo "${issue}" | jq -r .title)

  echo "------------------------------------------------"
  echo "------------------------------------------------"
  echo "||                                            ||"
  echo "||         Compiling application              ||"
  echo "||                                            ||"
  echo "------------------------------------------------"
  echo "------------------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo ""
  echo ""

  echo "STEP 1 OF 1: Compiling app ..."

  DIR=src/github.com/$GITHUB_REPOSITORY

  apk update && apk add --no-cache git;\
    go get -u \
    github.com/golang/dep/cmd/dep \
    gopkg.in/src-d/go-kallax.v1/...;\
    go install gopkg.in/src-d/go-kallax.v1/;\
    cp $GOPATH/bin/kallax /bin/kallax

  cd "$GOPATH/$DIR"

  dep ensure -vendor-only

  go generate

  CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" cmd/streaming/main.go

  chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"✅ COMPILE: Compiled successfully! \
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ⭐\"}")

  echo "PROJECT COMPILED!"
}

main "$@"
