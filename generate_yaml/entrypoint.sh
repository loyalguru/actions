#!/bin/sh -l

send_chat_message()
{
  chat_path="/chat.sh"

  type=$1
  message=$2

  sh -c "$chat_path $type \"$message\""
}

abort()
{
    echo "...error!"
    echo ""
    echo ""

    message="DEPLOY: Deploy action failed. Please go to project *${GITHUB_REPOSITORY}* -> Actions to see the errors."
    type="failed"
    send_chat_message "$type \"$message\""

    exit 1
}

trap 'abort' 0

set -e

main(){
  is_staging="true"
  ready="false"

  if [ -z "${DEPLOY_ENVIRONMENT}" ] && [ "$DEPLOY_ENVIRONMENT" = "production" ]; then
    is_staging="false"
  fi

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

  # Generate app.yaml file
  
  echo "STEP 1 OF 1: Generating app.yaml file..."

  FILE=app_example.yaml
  deploy_environment="Production"
  if [ "$is_staging" = "true" ]; then
    deploy_environment="Staging"
    FILE=app_example_staging.yaml
  fi

  if [ -f "$FILE" ]; then
      ready="true"
  fi

  if [ "$ready" = "true" ]; then

    db_full_url=$INPUT_DB_FULL_URL
    google_pub_sub_credentials=$INPUT_GOOGLE_PUBSUB_CREDENTIALS
    if [ "$is_staging" = "true" ]; then
      db_full_url=$INPUT_DB_FULL_URL_STAGING
      google_pub_sub_credentials=$INPUT_GOOGLE_PUBSUB_CREDENTIALS_STAGING
    fi

    sed -i -e "s#@SECRET_KEY@#\"${INPUT_SECRET_KEY}\"#g" $FILE
    sed -i -e "s#@DB_FULL_URL@#\"${db_full_url}\"#g" $FILE
    sed -i -e "s/@REDIS_CACHE_USER@/'${INPUT_REDIS_CACHE_USER}'/g" $FILE
    sed -i -e "s/@REDIS_CACHE_PASSWORD@/'${INPUT_REDIS_CACHE_PASSWORD}'/g" $FILE
    sed -i -e "s/@REDIS_SIDEKIQ_USER@/'${INPUT_REDIS_SIDEKIQ_USER}'/g" $FILE
    sed -i -e "s/@REDIS_SIDEKIQ_PASSWORD@/'${INPUT_REDIS_SIDEKIQ_PASSWORD}'/g" $FILE
    sed -i -e "s#@AWS_ACCESS_KEY_ID@#'${INPUT_AWS_ACCESS_KEY_ID}'#g" $FILE
    sed -i -e "s#@AWS_SECRET_ACCESS_KEY@#'${INPUT_AWS_SECRET_ACCESS_KEY}'#g" $FILE
    sed -i -e "s/@DATADOG_API_KEY@/'${INPUT_DATADOG_API_KEY}'/g" $FILE
    sed -i -e "s#@SENTRY_DSN@#\'${INPUT_SENTRY_DSN}'#g" $FILE
    PUBSUBCREDENTIALS=$(echo "$google_pub_sub_credentials" | base64 -d)
    echo "  GOOGLE_PUBSUB_CREDENTIALS: '$PUBSUBCREDENTIALS'" >> $FILE

    mv $FILE app.yaml
  else
    echo "${FILE} file don't exist."

    message="GENERATE YAML: failed to generate the file, ${FILE} file don't exist."
    type="failed"
    send_chat_message "$type \"$message\""

    exit 1
  fi

  echo "..done"
  echo ""
  echo ""

  message="GENERATE YAML: YAML file generation finished succeed. Starting deploy action to *$deploy_environment*..."
  type="thumbs"
  send_chat_message "$type \"$message\""

}

main "$@"

trap : 0

echo "READY TO DEPLOY"
