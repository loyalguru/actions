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

  if [ ! -z "${DEPLOY_ENVIRONMENT}" ] && [ "${DEPLOY_ENVIRONMENT}" = "production" ]; then
    is_staging="false"
  fi

  environment="${DEPLOY_ENVIRONMENT}"

  echo "-----------------------------------------------"
  echo "-----------------------------------------------"
  echo "||                                           ||"
  echo "||      Building Javascript application      ||"
  echo "||                                           ||"
  echo "-----------------------------------------------"
  echo "-----------------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo "Deploy to: $DEPLOY_ENVIRONMENT, is_staging = $is_staging"
  echo ""
  echo ""

  echo "STEP 1 OF 1: Building application ..."

  NG_PATH=$(command -v ng)

  node --max_old_space_size=4000 "$NG_PATH" build --env "$DEPLOY_ENVIRONMENT" --aot

  echo "..done"
  echo ""
  echo ""
}

main "$@"

trap : 0

echo "READY TO DEPLOY"
