#!/bin/bash -l

set -e

icon=""
message=""
error_message=""
infoWidgets=""
migration_message=""

messageType() {
    case "$type" in
        "success")
            icon="✔"
            message="Deploy success"
            ;;
        "failed")
            icon="🚫"
            message="Deploy error"
            ;;
        "action")
            icon="⚡"
            message="Deploy started"
            ;;
        *)
            error_message="Invalid type defined"
            exit 1
            ;;
    esac
}

abort()
{
    echo "...error!"
    echo ""
    echo ""

    message="Unexpected failure. Please go to project ${GITHUB_REPOSITORY} -> Actions to see the errors."
    type="failed"

    if [ "$error_message" != "" ]; then
        message=$error_message
    fi

    send_chat_message $type "$environment" "$message"

    exit 1
}

trap 'abort' 0

add_info_widget() {
    infoIcon=$1
    infoLabel=$2
    infoText=$3
    buttonText=$4
    buttonAction=$5

    if [ -z "$infoWidgets" ]; then
        infoWidgets=""
    fi

    if [ -n "$infoWidgets" ]; then
        infoWidgets+=","
    fi

    buttonWidget=""
    if [ -n "$buttonText" ] && [ -n "$buttonAction" ]; then
        buttonWidget="
        'button': {
            'text': '$buttonText',
            'onClick': {
                'openLink': {
                    'url': '$buttonAction'
                }
            }
        },
        "
    fi

    infoWidgets+="
    {
        'decoratedText': {
            'startIcon': {
                'knownIcon': '$infoIcon'
            },
            $buttonWidget
            'topLabel': '$infoLabel',
            'text': '$infoText'
        }
    }
    "
}

publish_message() {
    issue_number=$(jq -r .number "${GITHUB_EVENT_PATH}")

    issue_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${issue_number}"

    issue_info=$(curl -X GET "${issue_url}" \
        -H "Authorization: token ${TOKEN}")

    title=$(echo "${issue_info}" | jq -r .title)

    add_info_widget 'MAP_PIN' 'Repository' "${GITHUB_REPOSITORY}" "Go to Repository" "https://github.com/${GITHUB_REPOSITORY}"
    add_info_widget 'DESCRIPTION' 'Description' "${title}"
    add_info_widget 'BOOKMARK' 'Environment' "<font color=\"#4bdb5e\"><b>${environment}</b></font>"
    add_info_widget 'PERSON' 'Deployer' "${GITHUB_ACTOR}" "View Profile" "https://github.com/${GITHUB_ACTOR}"

    if [ "$error_message" != "" ]; then
        type=failed
        messageType

        add_info_widget 'CONFIRMATION_NUMBER_ICON' 'Error' "<font color=\"#f22b24\">$error_message</font>"
    fi

    if [ "$migration_message" != "" ]; then
        add_info_widget 'STAR' '' "$migration_message"
    fi

    link=$(jq -r .pull_request._links.html.href "${GITHUB_EVENT_PATH}")

    if [ -n "${replace_message}" ]; then
        method="PUT"
        chat_url="https://chat.googleapis.com/v1/$replace_message?key=${CKEY}&token=${CTOKEN}"
    else
        method="POST"
        chat_url="https://chat.googleapis.com/v1/spaces/${SPACE}/messages?key=${CKEY}&token=${CTOKEN}"
    fi

    chat=$(curl -s -X $method \
    "$chat_url" \
    -H 'Content-Type: application/json' \
    -d \
      "
      {
          'cardsV2': [{
              'cardId': 'createCardMessage',
              'card': {
                  'header': {
                      'title': '${icon} ${message}',
                      'subtitle': 'Project deployment - ${GITHUB_REPOSITORY}',
                      'imageUrl': 'https://strategyinsights.eu/wp-content/uploads/2022/07/Loyal-Guru-Logo.jpeg',
                      'imageType': 'CIRCLE',
                      'imageAltText': 'Deploy Bot'
                  },
                  'sections': [
                      {
                          'header': 'Repository info',
                          'collapsible': false,
                          'widgets': [
                            $infoWidgets
                          ]
                      },

                      {
                          'header': 'Buttons',
                          'collapsible': true,
                          'uncollapsibleWidgetsCount': 1,
                          'widgets': [
                              {
                                  'buttonList': {
                                      'buttons': [
                                        {
                                              'text': 'View Pull Request',
                                              'onClick': {
                                                  'openLink': {
                                                      'url': '$link'
                                                  }
                                              }
                                          },
                                          {
                                              'text': 'Go to actions',
                                              'onClick': {
                                                  'openLink': {
                                                      'url': '$link/checks'
                                                  }
                                              }
                                          }
                                      ]
                                  }
                              }
                          ]
                      }
                  ]
              }
          }]
      }
      "
   )

    messageId=$(echo "$chat" | jq -r .name)

    export MESSAGE_ID=$messageId

    echo "${chat}" > /dev/null
}

send_chat_message() {
    type=$1
    environment=$2
    err=$3
    migration=$4

    messageType

    if [ "$err" != "" ]; then
        error_message="${err}"
    fi

    if [ "$migration" != "" ]; then
        migration_message="Change with Migration"
    fi

    publish_message
}

trap : 0
