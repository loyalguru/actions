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
  echo "||      Deploying to Firebase                 ||"
  echo "||                                            ||"
  echo "------------------------------------------------"
  echo "------------------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo ""
  echo ""

  echo "STEP 1 OF 1: Deploying to Firebase ..."

  if [ -z "$INPUT_APPLICATION_CREDENTIALS" ]; then
    message="🛂 APPLICATION_CREDENTIALS not found"
    type="failed"
    send_chat_message "$type \"$environment\" \"$message\""
    trap : 0
    exit 1
  fi

  echo "${INPUT_APPLICATION_CREDENTIALS}" | base64 -d > /tmp/account.json
  export GOOGLE_APPLICATION_CREDENTIALS=/tmp/account.json

  command="firebase deploy -P $DEPLOY_ENVIRONMENT"
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
