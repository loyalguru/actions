#!/bin/sh -l

set -e

main(){

  type=$1
  message=$2

  icon=""
  if [ "$type" = "success" ]; then
    icon="✔"
  fi
  if [ "$type" = "loading" ]; then
    icon="🔄"
  fi
  if [ "$type" = "failed" ]; then
    icon="🚫"
  fi
  if [ "$type" = "thumbs" ]; then
    icon="👍"
  fi
  if [ "$type" = "stars" ]; then
    icon="⭐"
  fi
  if [ "$type" = "other" ]; then
    icon=$3
  fi

  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")
  title=$(echo "${issue}" | jq -r .title)

  chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${SPACE}/messages?key=${CKEY}&token=${CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"${icon} ${message} \n Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ${icon}\"}")

}

main "$@"
