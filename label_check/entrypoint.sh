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
    action=$(jq --raw-output .action ${GITHUB_EVENT_PATH})
    number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})

    echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
    echo "checking labels ${GITHUB_REPOSITORY}"
    
    issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${TOKEN}")

    echo "${issue}"
 
    labels=$(echo "${issue}" | jq -r .labels)

    production_label="deploy"
    staging_label="deploy_staging"

    production_target="N"
    staging_target="N"

    has_deploy_label="N"
    label_to_check=""

    echo "${labels}"
    
    # Reading labels
    for row in $(echo "${labels}" | jq -r '.[] | @base64'); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }
        label_name=$(_jq '.name')

        if [ "$label_name" = "$production_label" ]; then
            echo "...has '${production_label}' label..."
            production_target="Y"
            label_to_check=$production_label
            DEPLOY_ENVIRONMENT="production"
            echo "::set-env name=DEPLOY_ENVIRONMENT::production"
        fi

        if [ "$label_name" = "$staging_label" ]; then
            echo "...has '${staging_label}' label..."
            staging_target="Y"
            
        fi
    done

    if [[ $production_target = "N" ]]  && [[ $staging_target = "N" ]]; then
        echo "..has no deploy label. Exiting now."
        trap : 0
        exit 0
    fi

    if [ $staging_target = "Y" ]; then
        DEPLOY_ENVIRONMENT="staging"
        echo "::set-env name=DEPLOY_ENVIRONMENT::staging"
        label_to_check=$staging_label
        if [ $production_target = "Y" ]; then
            resp_del2=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${production_label}" \
                -H "Authorization: token ${TOKEN}")
            echo "... both production and staging labels found. Staging overrides production..."
        fi
        production_target="N"
    fi

    echo "...done"

    type="action"
    send_chat_message "$type \"$label_to_check\""

    # Check if another PR has deploy or deploy_staging label
    echo ""
    echo ""
    echo "Checking if another PR has ${label_to_check} label..."

    issues=$(curl -X GET "https://api.github.com/search/issues?q=is:pr+is:open+label:$label_to_check+repo:${GITHUB_REPOSITORY}" \
    -H "Authorization: token ${TOKEN}")

    count=$(echo "${issues}" | jq -r .total_count)

    echo ${issues}

    if [ $count != "1" ]; then
      echo "... another PR with ${label_to_check} found"

      # /repos/:owner/:repo/issues/:issue_number/labels/:name
      resp_del=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/$label_to_check" \
      -H "Authorization: token ${TOKEN}")

      message="There is another deploy in course."
      type="failed"
      send_chat_message "$type \"$label_to_check\" \"$message\""

      echo "ERROR"
      exit 1
    fi

    echo "...done"

    # Check if branch is up to date with master
    branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})
    echo ""
    echo ""
    echo "Checking if ${branch} is up to date with master..."
    
    git config remote.origin.url "https://${GITHUB_ACTOR}:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

    git fetch 
    
    revision=$(git rev-list --left-right --count origin/master...origin/${branch} | head -c 1)

    echo "$(git rev-list --left-right --count origin/master...origin/${branch})"
    echo ${revision}

    if [ "$revision" != "0" ];then
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        echo " "
        echo "CANNOT DEPLOY YOUR BANCH IS BEHIND MASTER";
        echo " "
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        resp_del2=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/$label_to_check" \
        -H "Authorization: token ${TOKEN}")
        echo ${resp_del2}

        message="Your branch is behind master!"
        type="failed"
        send_chat_message "$type \"$label_to_check\" \"$message\""

        exit 1;
    fi
}

main "$@"

trap : 0

echo "LABELS CHECKED!"
