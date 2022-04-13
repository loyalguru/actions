#!/bin/sh -l

send_chat_message()
{
  chat_path="/chat.sh"

  type=$1
  environment=$2
  message=$3
  migration=$4

  sh -c "$chat_path $type \"$environment\" \"$message\" \"migration\""
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

  if [ "${DEPLOY_ENVIRONMENT}" != "staging" ] && [ "${DEPLOY_ENVIRONMENT}" != "staging_2" ] && [ "${DEPLOY_ENVIRONMENT}" != "staging_3" ] && [ "${DEPLOY_ENVIRONMENT}" != "production" ]; then
    echo "...${DEPLOY_ENVIRONMENT} is not a valid environment"
    echo "ERROR"
    exit 1
  fi

  app_name=${INPUT_HEROKU_APP_NAME_STAGING}
  if [ "${DEPLOY_ENVIRONMENT}" = "production" ]; then
    app_name=${INPUT_HEROKU_APP_NAME}

  elif [ "${DEPLOY_ENVIRONMENT}" = "staging_2" ]; then
    app_name=${INPUT_HEROKU_APP_NAME_STAGING_TWO}

  elif [ "${DEPLOY_ENVIRONMENT}" = "staging_3" ]; then
    app_name=${INPUT_HEROKU_APP_NAME_STAGING_THREE}

  fi

  # The preboot will be always active, only when the label “migration” is present will be disabled.
  if  [ "${DEPLOY_ENVIRONMENT}" = "production" ] && [ "${WITH_MIGRATION}" = "Y" ]; then
    heroku features:disable preboot -a ${app_name}
  fi
  
  # git config --global --add safe.directory /github/workspace
  
  git fetch --all --unshallow

  git push https://heroku:${HEROKU_API_KEY}@git.heroku.com/${app_name}.git HEAD:master -f

  if  [ "${DEPLOY_ENVIRONMENT}" = "production" ] && [ "${WITH_MIGRATION}" = "Y" ]; then
    heroku features:enable preboot -a ${app_name}
  fi

  migration_message=""
  if [ "${WITH_MIGRATION}" = "Y" ]; then
    migration_message="true"
  fi

  if [ "${DEPLOY_ENVIRONMENT}" != "production" -a "${DEPLOY_ENVIRONMENT}" != "preproduction" ]; then
    heroku run --app ${app_name} rake db:migrate
  fi

  echo "...done"

  type="success"
  send_chat_message "$type \"$environment\" \"\" \"$migration_message\""
}

main "$@"

trap : 0

echo "DEPLOYED TO HEROKU!!"
