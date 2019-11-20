#!/bin/sh -l

set -e

main(){
    action=$(jq --raw-output .action ${GITHUB_EVENT_PATH})
    number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})

    echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"master\"}"
    
    issue=$(curl -s -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")
    title=$(echo "${issue}" | jq -r .title)

    echo ""
    echo ""
    echo "Checking if PR has '${INPUT_LABEL}' label..."
 

    labels=$(echo "${issue}" | jq -r .labels)
    has_required_label="nop"
    # Reading labels
    for row in $(echo "${labels}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        label_name=$(_jq '.name')

        if [ $label_name = ${INPUT_LABEL} ]; then
            echo "has ${INPUT_LABEL} label, we are good"
            has_required_label="yes"
        fi
    done

    if [ $has_required_label = "nop" ]; then
        echo "...has no ${INPUT_LABEL} label skipping"
        exit 0
    fi


    echo "...done"
    echo ""
    echo ""
    echo "Checking if '${INPUT_LABEL}' label was previously used..."


    chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"⚡ ${INPUT_LABEL}: Label set by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* ⚡\"}")


    issues=$(curl -s -X GET "https://api.github.com/search/issues?q=is:pr+is:open+label:${INPUT_LABEL}+repo:${GITHUB_REPOSITORY}" \
    -H "Authorization: token ${INPUT_TOKEN}")

    count=$(echo "${issues}" | jq -r .total_count)

    echo ${issues}


    if [ $count != "1" ]; then
      echo "Another branch with ${INPUT_LABEL} label is already being tested"
      # /repos/:owner/:repo/issues/:issue_number/labels/:name
      resp_del=$(curl -s -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${INPUT_LABEL}" \
      -H "Authorization: token ${INPUT_TOKEN}")
      echo ${resp_del}

      chat=$(curl -s -X POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"🚫  🚫 ${INPUT_LABEL}: Another branch with ${INPUT_LABEL} label is already being tested. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* 🚫  🚫\"}")

      exit 1
    fi



    echo "...done"
    echo ""
    echo ""
    echo "Checking if branch is up to date with master..."



    branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})
    
    git config remote.origin.url "https://${GITHUB_ACTOR}:${INPUT_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

    git fetch 
    
    revision=$(git rev-list --left-right --count origin/master...origin/${branch} | head -c 1)


    if [ "$revision" != "0" ];then
        echo "YOUR BANCH IS BEHIND MASTER";
        resp_del2=$(curl -s -X DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${INPUT_LABEL}" \
        -H "Authorization: token ${INPUT_TOKEN}")


        chat=$(curl -s -X POST \
        "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\" : \"🚫  🚫 ${INPUT_LABEL}: Not up to date with master. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* 🚫  🚫\"}")


        exit 1;
    fi


    chat=$(curl -s -X POST \
        "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\" : \"⭐ ⭐ ${INPUT_LABEL}: You can now test your branch. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* ⭐ ⭐\"}")



    echo "...done"
    echo ""
    echo ""
    echo "READY TO DEPLOY"
}

main "$@"