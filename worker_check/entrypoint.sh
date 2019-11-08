#!/bin/sh -l

set -e

main(){

  ready="false"
  hold="false"
  release="false"
  tries="1"
  token=$INPUT_RAILSTOKEN

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

  hold=$(curl -s -X POST "https://api.loyal.guru/deploy" \
      -H "Authorization: Basic ${token}" \
      -H "Content-Type: application/json" \
      -d '{"action":"hold"}' \
      -o /dev/null \
      -w '%{http_code}')

  if [ $hold -ne 201 ]; then
    echo "Hold: unexpected response. Check if hold has been applied and retry. EXITING NOW..."

    chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"🚫 WORKERS CHECK Hold: unexpected response. Check if hold has been applied and retry. \
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* 🚫\"}")

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

    chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"⭐ WORKERS CHECK: Ready to deploy.\
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ⭐\"}")

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

      chat=$(curl -s -X POST \
      "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
      -H 'Content-Type: application/json' \
      -d "{\"text\" : \"🚫 WORKERS CHECK Release: unexpected response. Check if release has been applied and retry. \
          Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* 🚫\"}")

      exit 1
    fi

    echo "...done"
    echo ""
    echo ""

    chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"⚡ WORKERS CHECK: Timeout. Semaphores have been released. \
        Deployer: *${GITHUB_ACTOR}*. PR: *${title}*. Project: *${GITHUB_REPOSITORY}* ⚡\"}")
  
    echo "FAIL: WORKERS RUNNING"
  fi
}

main "$@"
