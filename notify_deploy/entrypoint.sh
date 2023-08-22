#!/bin/bash -l

abort()
{
    echo "...error!"
    echo ""
    echo ""

    exit 1
}

trap 'abort' 0

set -e

main() {
    type=$1
    environment=$2
    err=$3
    migration=$4
    replace_message_id=$5

    chat_path=${ACTION_PATH}"chat.sh"

    if [ -f "$chat_path" ]; then
        # shellcheck source=chat.sh
        . "$chat_path"
        send_chat_message "$type" "$environment" "$err" "$migration" "$replace_message_id"

        echo "message_id=$MESSAGE_ID" >> "$GITHUB_OUTPUT"
    else
        echo $chat_path " does not exist"
    fi

    time=$(date)
    echo "time=$time" >> "$GITHUB_OUTPUT"
}

main "$@"

trap : 0