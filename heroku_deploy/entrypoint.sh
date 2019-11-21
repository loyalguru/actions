#!/bin/sh -l

set -e

main(){
  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})
  issue=$(curl -s -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")
  title=$(echo "${issue}" | jq -r .title)

  echo "-------------------------------------"
  echo "-------------------------------------"
  echo "||                                 ||"
  echo "||        Deploy to heroku         ||"
  echo "||                                 ||"
  echo "-------------------------------------"
  echo "-------------------------------------"

  echo ""
  echo ""
  echo "Deploy ${branch}..."


  $(curl -s -X POST \
        "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\" : \"⭐ ⭐ MANAGEMENT API: Branch ${branch} will be deployed. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* ⭐ ⭐\"}")

  git push https://heroku:${INPUT_HEROKU_API_KEY}@git.heroku.com/${INPUT_HEROKU_APP_NAME}.git HEAD:master -f

  echo "...done"

  $(curl -s -X POST \
        "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\" : \"⭐ ⭐ MANAGEMENT API: Branch ${branch} deployed. Run any migration or rake needed. Deployed by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* ⭐ ⭐\"}")
}

main "$@"
