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

    message="*HEROKU DEPLOY*: Heroku deploy. Please go to project *${GITHUB_REPOSITORY}* -> Actions to see the errors."
    type="failed"
    send_chat_message "$type \"$message\""

    exit 1
}

trap 'abort' 0

set -e

main(){
  branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})

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

  message="*HEROKU DEPLOY: Branch ${branch} will be deployed"
  type="action"
  send_chat_message "$type \"$message\""
  
  
  app_name=${INPUT_HEROKU_APP_NAME_STAGING}
  if [ "${DEPLOY_ENVIRONMENT}" = "production" ]; then
    app_name=${INPUT_HEROKU_APP_NAME}
  fi
  
  git push https://heroku:${INPUT_HEROKU_API_KEY}@git.heroku.com/${app_name}.git HEAD:master -f

  echo "...done"


  message="HEROKU DEPLOY: Branch ${branch} deployed. Run any migration or rake needed."
  type="stars"
  send_chat_message "$type \"$message\""
}

main "$@"

trap : 0

echo "DEPLOYED TO HEROKU!!"
