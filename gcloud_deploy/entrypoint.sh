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

    message="*DEPLOY*: Deploy action failed. Please go to project *${GITHUB_REPOSITORY}* -> Actions to see the errors."
    type="failed"
    send_chat_message "$type \"$message\""

    exit 1
}

trap 'abort' 0

set -e

main(){

  is_staging="false"
  if [ ! -z "${DEPLOY_ENVIRONMENT}" ] && [ "${DEPLOY_ENVIRONMENT}" = "staging" ]; then
    is_staging="true"
  fi

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

  export PATH=$PATH:/google-cloud-sdk/bin

  if [ ! -d "$HOME/.config/gcloud" ]; then
     if [ -z "${INPUT_APPLICATION_CREDENTIALS}" ]; then
        echo "APPLICATION_CREDENTIALS not found. Exiting...."

        message="*DEPLOY*: Deploy action failed. 🛂 APPLICATION_CREDENTIALS not found. Exiting...."
        type="failed"
        send_chat_message "$type \"$message\""

        exit 1
     fi

     if [ -z "${INPUT_PROJECT_ID}" ]; then
        echo "PROJECT_ID not found. Exiting...."

        message="*DEPLOY*: Deploy action failed. 🛂 PROJECT_ID not found. Exiting...."
        type="failed"
        send_chat_message "$type \"$message\""

        exit 1
     fi

     echo "${INPUT_APPLICATION_CREDENTIALS}" | base64 -d > /tmp/account.json

     gcloud auth activate-service-account --key-file=/tmp/account.json
     echo "This is the project: $INPUT_PROJECT_ID"
     gcloud config set project "$INPUT_PROJECT_ID"
  fi

  message="*DEPLOY*: Starting deployment to Google Cloud..."
  type="loading"
  send_chat_message "$type \"$message\""

  command_argument='--no-promote'
  if [ "$is_staging" = "true" ]; then
    command_argument=''
  fi
  command="gcloud app deploy app.yaml --quiet $command_argument"
  sh -c "$command"

  echo "...done!"
  echo ""
  echo ""

  message="*DEPLOY*: Deploy action finished succeed! 🎉🎉"
  type="success"
  send_chat_message "$type \"$message\""
}

main "$@"

trap : 0

echo "PROJECT DEPLOYED!"
