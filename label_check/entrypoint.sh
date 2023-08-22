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
    action=$(jq --raw-output .action ${GITHUB_EVENT_PATH})
    number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})

    echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
    echo "checking labels ${GITHUB_REPOSITORY}"

    issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${TOKEN}")

    echo "${issue}"

    labels=$(echo "${issue}" | jq -r .labels)

    production_label="deploy"
    migration_label="migration"
    staging_label="deploy_staging"
    staging_label_two="deploy_staging2"
    staging_label_three="deploy_staging3"
    staging_label_four="deploy_staging4"

    production_target="N"
    staging_target="N"

    has_deploy_label="N"
    label_to_check=""
    has_migration_label="N"
    migration_message=""

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
            echo "DEPLOY_ENVIRONMENT=production" >> $GITHUB_ENV

        fi

        if [ "$label_name" = "$staging_label" ]; then
            echo "...has '${staging_label}' label..."
            staging_target="Y"
            DEPLOY_ENVIRONMENT="staging"
            label_to_check=$staging_label

        elif [ "$label_name" = "$staging_label_two" ]; then
            echo "...has '${staging_label_two}' label..."
            staging_target="Y"
            DEPLOY_ENVIRONMENT="staging2"
            label_to_check=$staging_label_two

        elif [ "$label_name" = "$staging_label_three" ]; then
            echo "...has '${staging_label_three}' label..."
            staging_target="Y"
            DEPLOY_ENVIRONMENT="staging3"
            label_to_check=$staging_label_three
        fi

        elif [ "$label_name" = "$staging_label_four" ]; then
            echo "...has '${staging_label_four}' label..."
            staging_target="Y"
            DEPLOY_ENVIRONMENT="staging4"
            label_to_check=$staging_label_four
        fi

        if [ "$label_name" = "$migration_label" ]; then
            echo "...with '${migration_label}'..."
            has_migration_label="Y"
        fi
    done

    if [[ $production_target = "N" ]]  && [[ $staging_target = "N" ]]; then
        echo "..has no deploy label. Exiting now."
        trap : 0
        exit 0
    fi

    if [ $staging_target = "Y" ]; then
        echo "DEPLOY_ENVIRONMENT=${DEPLOY_ENVIRONMENT}" >> $GITHUB_ENV
        if [ $production_target = "Y" ]; then
            resp_del2=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${production_label}" \
                -H "Authorization: token ${TOKEN}")
            echo "... both production and staging labels found. Staging overrides production..."
        fi
        production_target="N"
    fi

    if [ $production_target = "Y" ] && [ $has_migration_label = "Y" ]; then
        echo "WITH_MIGRATION=${has_migration_label}" >> $GITHUB_ENV
        migration_message="true"
    fi

    echo "...done"

    type="action"
    send_chat_message "$type \"$DEPLOY_ENVIRONMENT\" \"\" \"$migration_message\""

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
      send_chat_message "$type \"$DEPLOY_ENVIRONMENT\" \"$message\""
      trap : 0
      echo "ERROR"
      exit 1
    fi

    echo "...done"

    repo=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}" \
    -H "Authorization: token ${TOKEN}")

    default_branch=$(echo "${repo}" | jq -r .default_branch)

    # Check if branch is up to date with default branch
    branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})
    echo ""
    echo ""
    echo "Checking if ${branch} is up to date with ${default_branch}..."

    git config remote.origin.url "https://${GITHUB_ACTOR}:${TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

    git fetch

    revision=$(git rev-list --left-right --count origin/${default_branch}...origin/${branch} | head -c 1)

    echo "$(git rev-list --left-right --count origin/${default_branch}...origin/${branch})"
    echo ${revision}

    if [ "$revision" != "0" ];then
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        echo " "
        echo "CANNOT DEPLOY YOUR BANCH IS BEHIND ${default_branch}";
        echo " "
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        resp_del2=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/$label_to_check" \
        -H "Authorization: token ${TOKEN}")
        echo ${resp_del2}

        message="Your branch is behind ${default_branch}!"
        type="failed"
        send_chat_message "$type \"$DEPLOY_ENVIRONMENT\" \"$message\""
        trap : 0
        exit 1;
    fi
}

main "$@"

trap : 0

echo "LABELS CHECKED!"
