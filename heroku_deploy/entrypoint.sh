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

  if [ -z "${DEPLOY_ENVIRONMENT}" ] || [ "${DEPLOY_ENVIRONMENT}" != "production" ]; then
    echo "...not being executed on production environment"
    echo "ERROR"
    exit 0
  fi

  message="*HEROKU DEPLOY: Branch ${branch} will be deployed"
  type="action"
  send_chat_message "$type \"$message\""

  git push https://heroku:${INPUT_HEROKU_API_KEY}@git.heroku.com/${INPUT_HEROKU_APP_NAME}.git HEAD:master -f

  echo "...done"


  message="HEROKU DEPLOY: Branch ${branch} deployed. Run any migration or rake needed."
  type="stars"
  send_chat_message "$type \"$message\""
}

main "$@"

trap : 0

echo "DEPLOYED TO HEROKU!!"