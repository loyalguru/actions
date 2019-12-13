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

    message="*WORKER CHECK*: Worker check failed. Please go to project *${GITHUB_REPOSITORY}* -> Actions to see the errors."
    type="failed"
    send_chat_message "$type \"$message\""

    exit 1
}

trap 'abort' 0

set -e

main(){

  ready="false"
  hold="false"
  release="false"
  tries="1"
  token=$INPUT_RAILSTOKEN
  
  number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})
  issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${TOKEN}")
  echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
  title=$(echo "${issue}" | jq -r .title)

  echo "-------------------------------------"
  echo "-------------------------------------"
  echo "||                                 ||"
  echo "||      Check blocking workers     ||"
  echo "||                                 ||"
  echo "-------------------------------------"
  echo "-------------------------------------"

  echo ""
  echo "Started at $(date)"
  echo ""
  echo ""

  # Hold

  echo ""
  echo "STEP 1 OF 2: Holding semaphores..."
  
  if [ -z "${DEPLOY_ENVIRONMENT}" ] || [ "${DEPLOY_ENVIRONMENT}" != "production" ]; then
    echo "...no targeting production deploy"
    echo "ERROR"
    exit 1
  fi

  hold=$(curl -s -X POST "https://api.loyal.guru/deploy" \
      -H "Authorization: Basic ${token}" \
      -H "Content-Type: application/json" \
      -d '{"action":"hold"}' \
      -o /dev/null \
      -w '%{http_code}')

  if [ $hold -ne 201 ]; then
    echo "Hold: unexpected response. Check if hold has been applied and retry. EXITING NOW..."

    message="*WORKERS CHECK Hold*: unexpected response. Check if hold has been applied and retry."
    type="failed"
    send_chat_message "$type \"$message\""

    exit 1
  fi
  echo "...done"

  echo ""
  echo ""
  echo ""

  # Wait
  
  echo "STEP 2 OF 2: Waiting for workers..."

  while [[ "$ready" != "true" ]] && [[ $tries -lt 60 ]]
  do
    let "tries = tries +  1"

    ready=$(curl -s -X POST "https://api.loyal.guru/deploy" \
      -H "Authorization: Basic ${token}" \
      -H "Content-Type: application/json" \
      -d '{"action":"check"}')

    if [ "$ready" = "true" ]; then
      echo "no workers running"
    else
      echo "Workers running, checking again in 30 seconds..."
      sleep 30
    fi
  done

  if [ "$ready" = "true" ]; then
    echo "..done"
    echo ""
    echo ""

    message="*WORKERS CHECK*: Ready to deploy."
    type="stars"
    send_chat_message "$type \"$message\""

    echo "READY TO DEPLOY"
  else
    # Release semaphores

    echo "Waited 30 minutes, releasing semaphores..."
    release=$(curl -s -X POST "https://api.loyal.guru/deploy" \
      -H "Authorization: Basic ${token}" \
      -H "Content-Type: application/json" \
      -d '{"action":"release"}' \
      -o /dev/null \
      -w '%{http_code}')

    if [ $hold -ne 201 ]; then
      echo "Release: unexpected response. Check if release has been applied and retry. EXITING NOW..."

      message="*WORKERS CHECK Release*: unexpected response. Check if release has been applied and retry."
      type="failed"
      send_chat_message "$type \"$message\""

      exit 1
    fi

    echo "...done"
    echo ""
    echo ""

    message="*WORKERS CHECK*: Timeout. Semaphores have been released."
    type="action"
    send_chat_message "$type \"$message\""

    echo "FAIL: WORKERS RUNNING"
    exit 1
  fi
}

main "$@"

trap : 0

echo "WORKERS CHECK FINISHED!"
