#!/bin/sh -l

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

  is_staging="false"
  if [ ! -z "${DEPLOY_ENVIRONMENT}" ] && [ "${DEPLOY_ENVIRONMENT}" = "staging" ]; then
    is_staging="true"
  fi

  environment="${DEPLOY_ENVIRONMENT}"

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

        message="🛂 APPLICATION_CREDENTIALS not found"
        type="failed"
        send_chat_message "$type \"$environment\" \"$message\""

        exit 1
     fi

     if [ -z "${INPUT_PROJECT_ID}" ]; then
        echo "PROJECT_ID not found. Exiting...."

        message="🛂 PROJECT_ID not found"
        type="failed"
        send_chat_message "$type \"$environment\" \"$message\""

        exit 1
     fi

     echo "${INPUT_APPLICATION_CREDENTIALS}" | base64 -d > /tmp/account.json

     gcloud auth activate-service-account --key-file=/tmp/account.json
     echo "This is the project: $INPUT_PROJECT_ID"
     gcloud config set project "$INPUT_PROJECT_ID"
  fi

  command_argument='--no-promote'
  if [ "$is_staging" = "true" ]; then
    command_argument=''
  fi
  command="gcloud app deploy app.yaml --quiet $command_argument"
  sh -c "$command"

  echo "...done!"
  echo ""
  echo ""

  type="success"
  send_chat_message "$type \"$environment\""
}

main "$@"

trap : 0

echo "PROJECT DEPLOYED!"
