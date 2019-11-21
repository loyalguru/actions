#!/bin/sh -l

set -e

main(){
  ready="false"
  
  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")
  echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
  title=$(echo "${issue}" | jq -r .title)

  echo "-------------------------------------"
  echo "-------------------------------------"
  echo "||                                 ||"
  echo "||      Generating YAML file       ||"
  echo "||                                 ||"
  echo "-------------------------------------"
  echo "-------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo ""
  echo ""

  # Generate app.yml file
  
  echo "STEP 1 OF 1: Generating app.yml file..."

  pwd

  FILE=app_example.yaml

  if [ -f "$FILE" ]; then
      ready="true"
  fi

  if [ "$ready" = "true" ]; then
    cp -vap app_example.yml app.yaml

    FILE=app.yaml

    sed -i "" "s/\${{ SECRET_KEY }}/\"${INPUT_SECRET_KEY}\"/g" $FILE
    sed -i "" "s/\${{ DB_FULL_URL }}/\"${INPUT_DB_FULL_URL}\"/g" $FILE
    sed -i "" "s/\${{ REDIS_CACHE_USER }}/'${INPUT_REDIS_CACHE_USER}'/g" $FILE
    sed -i "" "s/\${{ REDIS_CACHE_PASSWORD }}/'${INPUT_REDIS_CACHE_PASSWORD}'/g" $FILE
    sed -i "" "s/\${{ REDIS_SIDEKIQ_USER }}/'${REDIS_SIDEKIQ_USER}'/g" $FILE
    sed -i "" "s/\${{ REDIS_SIDEKIQ_PASSWORD }}/'${REDIS_SIDEKIQ_PASSWORD}'/g" $FILE
    sed -i "" "s/\${{ AWS_ACCESS_KEY_ID }}/'${INPUT_AWS_ACCESS_KEY_ID}'/g" $FILE
    sed -i "" "s/\${{ AWS_SECRET_ACCESS_KEY }}/'${INPUT_AWS_SECRET_ACCESS_KEY}'/g" $FILE
    sed -i "" "s/\${{ DATADOG_API_KEY }}/'${INPUT_DATADOG_API_KEY}'/g" $FILE
    sed -i "" "s/\${{ SENTRY_DSN }}/'${INPUT_SENTRY_DSN}'/g" $FILE
    sed -i "" "s/\${{ GOOGLE_PUBSUB_CREDENTIALS }}/'${GOOGLE_PUBSUB_CREDENTIALS}'/g" $FILE
  else
    echo "${FILE} file don't exist."

    chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"🚫 GENERATE YAML: failed to generate the file, ${FILE} file don't exist. \
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* 🚫\"}")

    exit 1
  fi

  echo "..done"
  echo ""
  echo ""

  chat=$(curl -s -X POST \
  "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
  -H 'Content-Type: application/json' \
  -d "{\"text\" : \"⭐ DEPLOY: Starting deploy...\
      Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ⭐\"}")

  # TODO: Remove this line that test that generates well.
  cat app.yaml

  echo "READY TO DEPLOY"
}

main "$@"
