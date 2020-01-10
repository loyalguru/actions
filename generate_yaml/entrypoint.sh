#!/bin/bash

send_chat_message()
{
  chat_path="/chat.sh"

  type=$1
  environment=$2
  message=$3

  sh -c "$chat_path $type \"$environment\" \"$message\""
}

abort()
{
    echo "...error!"
    echo ""
    echo ""

    environment="${DEPLOY_ENVIRONMENT}"
    message="Unexpected failure. Please go to project ${GITHUB_REPOSITORY} -> Actions to see the errors."
    type="failed"
    send_chat_message "$type \"$environment\" \"$message\""

    exit 1
}

trap 'abort' 0

set -e

main(){
  is_staging="true"
  ready="false"

  if [ ! -z "${DEPLOY_ENVIRONMENT}" ] && [ "${DEPLOY_ENVIRONMENT}" = "production" ]; then
    is_staging="false"
  fi

  environment="${DEPLOY_ENVIRONMENT}"

  echo "-------------------------------------"
  echo "-------------------------------------"
  echo "||                                 ||"
  echo "||      Generating YAML file       ||"
  echo "||                                 ||"
  echo "-------------------------------------"
  echo "-------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo "Deploy to: $DEPLOY_ENVIRONMENT, is_staging = $is_staging"
  echo ""
  echo ""

  # Generate app.yaml file

  FILE=app_example.yaml
  deploy_env="Production"
  if [ "$is_staging" = "true" ]; then
    deploy_env="Staging"
    FILE=app_example_staging.yaml
  fi

  echo "STEP 1 OF 1: Generating app.yaml file from $FILE ..."

  if [ -f "$FILE" ]; then
      ready="true"
  fi

  if [ "$ready" = "true" ]; then
    db_full_url=$(printf "%q" "$INPUT_DB_FULL_URL")
    google_pub_sub_credentials=$INPUT_GOOGLE_PUBSUB_CREDENTIALS
    google_credentials=$INPUT_GOOGLE_CREDENTIALS
    launchdarkly_sdkkey=$INPUT_LAUNCHDARKLY_SDKKEY
    if [ "$is_staging" = "true" ]; then
      db_full_url=$(printf "%q" "$INPUT_DB_FULL_URL_STAGING")
      google_pub_sub_credentials=$INPUT_GOOGLE_PUBSUB_CREDENTIALS_STAGING
      google_credentials=$INPUT_GOOGLE_CREDENTIALS_STAGING
      launchdarkly_sdkkey=$INPUT_LAUNCHDARKLY_SDKKEY_STAGING
    fi
    sed -i -e "s#@SECRET_KEY@#\"${INPUT_SECRET_KEY}\"#g" $FILE
    sed -i -e "s#@DB_FULL_URL@#${db_full_url}#g" $FILE
    sed -i -e "s/@REDIS_CACHE_USER@/'${INPUT_REDIS_CACHE_USER}'/g" $FILE
    sed -i -e "s/@REDIS_CACHE_PASSWORD@/'${INPUT_REDIS_CACHE_PASSWORD}'/g" $FILE
    sed -i -e "s/@REDIS_SIDEKIQ_USER@/'${INPUT_REDIS_SIDEKIQ_USER}'/g" $FILE
    sed -i -e "s/@REDIS_SIDEKIQ_PASSWORD@/'${INPUT_REDIS_SIDEKIQ_PASSWORD}'/g" $FILE
    sed -i -e "s#@AWS_ACCESS_KEY_ID@#'${INPUT_AWS_ACCESS_KEY_ID}'#g" $FILE
    sed -i -e "s#@AWS_SECRET_ACCESS_KEY@#'${INPUT_AWS_SECRET_ACCESS_KEY}'#g" $FILE
    sed -i -e "s/@DATADOG_API_KEY@/'${INPUT_DATADOG_API_KEY}'/g" $FILE
    sed -i -e "s#@SENTRY_DSN@#\'${INPUT_SENTRY_DSN}'#g" $FILE
    sed -i -e "s#@LAUNCHDARKLY_SDKKEY@#\'${launchdarkly_sdkkey}'#g" $FILE
    if [ ! -z "${google_pub_sub_credentials}" ]; then
      PUBSUBCREDENTIALS=$(echo "$google_pub_sub_credentials" | base64 -d)
      echo "  GOOGLE_PUBSUB_CREDENTIALS: '$PUBSUBCREDENTIALS'" >> $FILE
    fi

    if [ ! -z "${google_credentials}" ]; then
      CREDENTIALS=$(echo "$google_credentials" | base64 -d)
      echo "  GOOGLE_CREDENTIALS: '$CREDENTIALS'" >> $FILE
    fi

    mv $FILE app.yaml
  else
    echo "${FILE} file don't exist."

    message="Failed to generate the file, ${FILE} file don't exist."
    type="failed"
    send_chat_message "$type \"$environment\" \"$message\""
    trap : 0
    exit 1
  fi

  echo "..done"
  echo ""
  echo ""

}

main "$@"

trap : 0

echo "READY TO DEPLOY"
