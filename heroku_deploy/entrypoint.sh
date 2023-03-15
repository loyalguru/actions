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
  
  git config --global --add safe.directory /github/workspace

  git push https://heroku:${HEROKU_API_KEY}@git.heroku.com/${app_name}.git HEAD:master -f

  if  [ "${DEPLOY_ENVIRONMENT}" = "production" ] && [ "${WITH_MIGRATION}" = "Y" ]; then
    heroku features:enable preboot -a ${app_name}
  fi

  migration_message=""
  if [ "${WITH_MIGRATION}" = "Y" ]; then
    migration_message="true"
  fi

  echo "...done"

  echo ""
  echo ""
  echo "Running migrations..."
  
  heroku run --app ${app_name} rake db:migrate


  echo "...done"


  echo ""
  echo ""
  echo "Replicating workers..."

  
  token=${INPUT_RAILSTOKEN}
  if [ "${DEPLOY_ENVIRONMENT}" = "staging" ]; then
    token=${INPUT_RAILSTOKEN_STAGING}

  elif [ "${DEPLOY_ENVIRONMENT}" = "staging_2" ]; then
    token=${INPUT_RAILSTOKEN_STAGING_TWO}

  elif [ "${DEPLOY_ENVIRONMENT}" = "staging_3" ]; then
    token=${INPUT_RAILSTOKEN_STAGING_THREE}

  fi

  url="https://api.loyal.guru/deploy/replicate_workers"
  if [ "${DEPLOY_ENVIRONMENT}" = "staging" ]; then
    url="https://staging.loyal.guru/deploy/replicate_workers"

  elif [ "${DEPLOY_ENVIRONMENT}" = "staging_2" ]; then
    url="https://loyal-guru-api-staging-2.herokuapp.com/deploy/replicate_workers"

  elif [ "${DEPLOY_ENVIRONMENT}" = "staging_3" ]; then
    url="https://loyal-guru-api-staging-3.herokuapp.com/deploy/replicate_workers"

  fi

  resp=$(curl -s -X POST ${url}\
      -H "Authorization: Basic ${token}" \
      -H "Content-Type: application/json" \
      -o /dev/null \
      -w '%{http_code}')

  echo $resp
  if [ $resp -ne 201 ]; then
    echo "Replicate workers: unexpected response. Code was deployed, please manually execute the replication. EXITING NOW..."

    message="Replicate workers: Unexpected response. Code was deployed, please manually execute the replication."
    type="failed"
    send_chat_message "$type \"$environment\" \"$message\""

    exit 1
  fi
  echo "...done"

  type="success"
  send_chat_message "$type \"$environment\" \"\" \"$migration_message\""
}

main "$@"

trap : 0

echo "DEPLOYED TO HEROKU!!"
