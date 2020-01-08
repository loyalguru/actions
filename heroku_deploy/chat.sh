#!/bin/sh -l

set -e

main(){

  type=$1
  environment=$2
  err=$3

  icon=""
  message=""
  if [ "$type" = "success" ]; then
    icon="✔"
    message="Deploy success"
  fi
  if [ "$type" = "failed" ]; then
    icon="🚫"
    message="Deploy error"
  fi
  if [ "$type" = "action" ]; then
    icon="⚡"
    message="Deploy started"
  fi

  error_message=""
  if [ "$err" != "" ]; then
    error_message="Motive: *${err}*"
  fi

  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${TOKEN}")
  title=$(echo "${issue}" | jq -r .title)

  chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${SPACE}/messages?key=${CKEY}&token=${CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"${icon} ${message} \n Environment: *${environment}* \n Project: *${GITHUB_REPOSITORY}* \n Pull Request: *${title}* \n Deployer: *${GITHUB_ACTOR}* \n ${error_message} \"}")

}

main "$@"