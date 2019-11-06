#!/bin/sh -l

set -e

main(){
    action=$(jq --raw-output .action ${GITHUB_EVENT_PATH})
    number=$(jq --raw-output .number ${GITHUB_EVENT_PATH})

    echo "DEBUG {\"title\":\"${labels}\", \"head\":\"${branch}\", \"base\": \"staging\"}"
    echo "checking labels ${GITHUB_REPOSITORY}"
    
    issue=$(curl -X GET "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${number}" \
    -H "Authorization: token ${GITHUB_TOKEN}")

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
}

main "$@"