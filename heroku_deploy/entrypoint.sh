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
    message="Unexpected failure. Please go to project *${GITHUB_REPOSITORY}* -> Actions to see the errors."
    type="failed"
    send_chat_message "$type \"$environment\" \"$message\""

    exit 1
}

trap 'abort' 0

set -e

main(){
  branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})

  environment="${DEPLOY_ENVIRONMENT}"

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

  if [ -z "${DEPLOY_ENVIRONMENT}" ]; then
    echo "...deploy environment not set"
    echo "ERROR"
    exit 1
  fi
  
  if [ "${DEPLOY_ENVIRONMENT}" != "staging" ] && [ "${DEPLOY_ENVIRONMENT}" != "production" ]; then
    echo "...${DEPLOY_ENVIRONMENT} is not a valid environment"
    echo "ERROR"
    exit 1
  fi

  app_name=${INPUT_HEROKU_APP_NAME_STAGING}
  if [ "${DEPLOY_ENVIRONMENT}" = "production" ]; then
    app_name=${INPUT_HEROKU_APP_NAME}
  fi
  
  git push https://heroku:${INPUT_HEROKU_API_KEY}@git.heroku.com/${app_name}.git HEAD:master -f

  echo "...done"

  type="success"
  send_chat_message "$type \"$environment\""
}

main "$@"

trap : 0

echo "DEPLOYED TO HEROKU!!"
