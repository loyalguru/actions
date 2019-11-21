#!/bin/sh

set -e

main(){

  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")
  title=$(echo "${issue}" | jq -r .title)

  echo "------------------------------------------------"
  echo "------------------------------------------------"
  echo "||                                            ||"
  echo "||      Deploying to Google Cloud Engine      ||"
  echo "||                                            ||"
  echo "------------------------------------------------"
  echo "------------------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo ""
  echo ""

  echo "STEP 1 OF 1: Deploying to gcloud ..."

  echo "$INPUT_APPLICATION_CREDENTIALS" | base64 -d > /tmp/account.json

  gcloud auth activate-service-account --key-file=/tmp/account.json
  gcloud config set project "$INPUT_PROJECT_ID"

  echo ::add-path::/google-cloud-sdk/bin/gcloud
  echo ::add-path::/google-cloud-sdk/bin/gsutil

  chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"🔄 DEPLOY: Starting deploy... \
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ⭐\"}")

  command="gcloud app deploy app.yaml"
  sh -c "$command"
  status=$?

  if [ $status -eq 0 ]; then
    echo "...done!"
    echo ""
    echo ""

    chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"✅ DEPLOY: Deploy action finished succeed! 🎉🎉 \
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ⭐\"}")

  else
    echo "...error!"
    echo ""
    echo ""

    chat=$(curl -s -X POST \
      "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
      -H 'Content-Type: application/json' \
      -d "{\"text\" : \"🚫 DEPLOY: Deploy action failed. Please go to project *${GITHUB_REPOSITORY}* -> Actions to see the errors. \
          Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* 🚫\"}")

    exit 1
  fi

  echo "PROJECT DEPLOYED!"
}

main "$@"
