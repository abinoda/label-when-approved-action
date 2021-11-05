#!/bin/bash
set -e

if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
  echo "Set the GITHUB_REPOSITORY env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

addLabel=$ADD_LABEL
if [[ -n "$LABEL_NAME" ]]; then
  echo "Warning: Plase define the ADD_LABEL variable instead of the deprecated LABEL_NAME."
  addLabel=$LABEL_NAME
fi

if [[ -z "$addLabel" ]]; then
  echo "Set the ADD_LABEL or the LABEL_NAME env variable."
  exit 1
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
title=$(jq --raw-output .pull_request.title "$GITHUB_EVENT_PATH")
user=$(jq --raw-output .pull_request.user.login "$GITHUB_EVENT_PATH")

handle() {
  # Try to get the JIRA ticket from the title
  TASK=$(echo "$title" | grep -E 'CN-[0-9]+' -o || true)

  # If no JIRA ticket is included, request changes
  if [[ -z "$TASK" || "$TASK" == " " ]]; then
    echo "No JIRA ticket found, requesting changes"
    curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"event\": \"REQUEST_CHANGES\",\"body\": \"@${user} o PR não possui o número do ticket do JIRA, por favor inclua um 'CN-XXXX | ' no início do título do seu PR\"}" \
        "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews"
  fi

  # Remove label before checking for approvals
  if [[ -n "$REMOVE_LABEL" ]]; then
    echo "Label ($REMOVE_LABEL) found, removing"
    curl -sSL \
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      -X DELETE \
      "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${REMOVE_LABEL}"
  fi
}

label_when_approved() {
  # https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
  body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews?per_page=100")
  reviews=$(echo "$body" | jq --raw-output '.[] | {state: .state, user: .user.login} | @base64' | sort | uniq)

  approvalsCounter=0

  # Loop for each review of the PR
  for encodedReview in $reviews; do
    review="$(echo "$encodedReview" | base64 -d)"
    reviewState=$(echo "$review" | jq --raw-output '.state')
    reviewUser=$(echo "$review" | jq --raw-output '.user')

    # Re-request stale reviews
    if [[ "$reviewState" == "DISMISSED" ]]; then
      echo "Dismissed PR from ($reviewUser) found, requesting"
      curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -d "{\"reviewers\":[\"$reviewUser\"]}" \
        "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/requested_reviewers"
    fi

    # Increase approval count
    if [[ "$reviewState" == "APPROVED" ]]; then
      approvalsCounter=$((approvalsCounter+1))
    fi

    # Apply label if we get enough approvals
    if [[ "$approvalsCounter" -ge "$APPROVALS" ]]; then
      echo "$approvalsCounter/$APPROVALS found, Labeling pull request"

      curl -sSL \
        -H "${AUTH_HEADER}" \
        -H "${API_HEADER}" \
        -X POST \
        -H "Content-Type: application/json" \
        -d "{\"labels\":[\"${addLabel}\"]}" \
        "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"

      break
    fi
  done
}

handle

if [[ "$action" == "submitted" ]] && [[ "$state" == "approved" ]]; then
  label_when_approved
else
  echo "Ignoring event ${action}/${state}"
fi
