#!/bin/sh -l

set -e

main(){
    action=$(jq --raw-output .action ${GITHUB_EVENT_PATH})
    number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})

    echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
    echo "checking labels ${GITHUB_REPOSITORY}"
    
    issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")

    echo "check done"

    echo ${issue}
 
    labels=$(echo "${issue}" | jq -r .labels)

    has_deploy_label="nop"

    echo ${labels}
    
    # Reading labels
    for row in $(echo "${labels}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        label_name=$(_jq '.name')

        if [ $label_name = "deploy" ]; then
            echo "has deploy label, we are good"
            has_deploy_label="yes"
        fi
    done

    if [ $has_deploy_label = "nop" ]; then
        echo "has no deploy label skiping"
        exit 1
    fi


    issues=$(curl -X GET "https://api.github.com/search/issues?q=is:pr+is:open+label:deploy+repo:${GITHUB_REPOSITORY}" \
    -H "Authorization: token ${INPUT_TOKEN}")

    count=$(echo "${issues}" | jq -r .total_count)

    echo ${issues}


    if [ $count != "1" ]; then
      echo "Deploy in course"
      # /repos/:owner/:repo/issues/:issue_number/labels/:name
      resp_del=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/deploy" \
      -H "Authorization: token ${INPUT_TOKEN}")
      echo ${resp_del}

      exit 1
    fi

    branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})
    
    git config remote.origin.url "https://${GITHUB_ACTOR}:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

    git fetch 
    
    revision=$(git rev-list --left-right --count origin/master...origin/${branch} | head -c 1)

    echo "revision"
    echo "$(git rev-list --left-right --count origin/master...origin/${branch})"
    echo ${revision}

    if [ "$revision" != "0" ];then
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        echo " "
        echo "CANNOT DEPLOY YOUR BANCH IS BEHIND MASTER";
        echo " "
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        resp_del2=$(curl -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/deploy" \
        -H "Authorization: token ${INPUT_TOKEN}")
        echo ${resp_del2}
        exit 1;
    fi

    
}

main "$@"