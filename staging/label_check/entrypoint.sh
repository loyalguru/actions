#!/bin/sh -l

set -e

main(){
    action=$(jq --raw-output .action ${GITHUB_EVENT_PATH})
    number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})

    echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
    
    issue=$(curl -X -s GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${INPUT_TOKEN}")

    echo ""
    echo ""
    echo "Checking if PR has 'staging' label..."
 

    labels=$(echo "${issue}" | jq -r .labels)
    has_required_label="nop"
    # Reading labels
    for row in $(echo "${labels}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 --decode | jq -r ${1}
        }
        label_name=$(_jq '.name')

        if [ $label_name = "staging" ]; then
            echo "has staging label, we are good"
            has_required_label="yes"
        fi
    done

    if [ $has_required_label = "nop" ]; then
        echo "...has no staging label skiping"
        exit 0
    fi


    echo "...done"
    echo ""
    echo ""
    echo "Checking if 'staging' label was previously used..."



    title=$(echo "${issue}" | jq -r .title)

    chat=$(curl -X -s POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"⚡ Staging slot requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* ⚡\"}")


    issues=$(curl -X GET "https://api.github.com/search/issues?q=is:pr+is:open+label:staging+repo:${GITHUB_REPOSITORY}" \
    -H "Authorization: token ${INPUT_TOKEN}")

    count=$(echo "${issues}" | jq -r .total_count)

    echo ${issues}


    if [ $count != "1" ]; then
      echo "Another branch is already being tested in staging"
      # /repos/:owner/:repo/issues/:issue_number/labels/:name
      resp_del=$(curl -X -s DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/staging" \
      -H "Authorization: token ${INPUT_TOKEN}")
      echo ${resp_del}

      chat=$(curl -X -s POST \
    "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
    -H 'Content-Type: application/json' \
    -d "{\"text\" : \"🚫  🚫 STAGING: Another branch is already being tested in staging. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* 🚫  🚫\"}")

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
        echo "CANNOT UPDATE TO STAGING YOUR BANCH IS BEHIND MASTER";
        resp_del2=$(curl -X -s DELETE "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/staging" \
        -H "Authorization: token ${INPUT_TOKEN}")


        chat=$(curl -X -s POST \
        "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\" : \"🚫  🚫 STAGING: Not up to date with master. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* 🚫  🚫\"}")


        exit 1;
    fi


    chat=$(curl -X -s POST \
        "https://chat.googleapis.com/v1/spaces/${INPUT_SPACE}/messages?key=${INPUT_CKEY}&token=${INPUT_CTOKEN}" \
        -H 'Content-Type: application/json' \
        -d "{\"text\" : \"⭐ ⭐ STAGING: You can now upload and test your branch. Requested by *${GITHUB_ACTOR}* on PR *${title}* project *${GITHUB_REPOSITORY}* ⭐ ⭐\"}")



    echo "...done"
    echo ""
    echo ""
    echo "READY TO MOVE TO STAGING"
}

main "$@"