#!/bin/sh -l

set -e

main(){
    branch=$(jq --raw-output .pull_request.head.ref ${GITHUB_EVENT_PATH})

    revision=$(git rev-list --left-right --count origin/master...${branch} | head -c 1)

    if [ "$revision" != "0" ];then
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        echo " "
        echo "CANNOT DEPLOY YOUR BANCH IS BEHIND MASTER";
        echo " "
        echo " 🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  🚫  "
        exit;
    fi
}

main "$@"