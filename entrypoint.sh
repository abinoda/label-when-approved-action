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

if [[ -z "$ADD_LABEL" ]]; then
  echo "Set the ADD_LABEL env variable."
  exit 1
fi

URI="https://api.github.com"
API_HEADER="Accept: application/vnd.github.v3+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
state=$(jq --raw-output .review.state "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")

label_when_approved() {
  # https://developer.github.com/v3/pulls/reviews/#list-reviews-on-a-pull-request
  body=$(curl -sSL -H "${AUTH_HEADER}" -H "${API_HEADER}" "${URI}/repos/${GITHUB_REPOSITORY}/pulls/${number}/reviews?per_page=100")
  reviews=$(echo "$body" | jq --raw-output '.[] | {state: .state} | @base64')

  approvals=0
  totalReviews=0

  for r in $reviews; do
    review="$(echo "$r" | base64 -d)"
    rState=$(echo "$review" | jq --raw-output '.state')

    totalReviews=$((totalReviews+1))

    if [[ "$rState" == "APPROVED" ]]; then
      approvals=$((approvals+1))
    fi

  done

  echo "${approvals}/${totalReviews} approvals"

  if [[ "$approvals" -ge "$APPROVALS" ]]; then
    echo "Labeling pull request as approved"

    curl -sSL \
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      -X POST \
      -H "Content-Type: application/json" \
      -d "{\"labels\":[\"${ADD_LABEL}\"]}" \
      "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels"

    if [[ -n "$REMOVE_LABEL" ]]; then
        curl -sSL \
          -H "${AUTH_HEADER}" \
          -H "${API_HEADER}" \
          -X DELETE \
          "${URI}/repos/${GITHUB_REPOSITORY}/issues/${number}/labels/${REMOVE_LABEL}"
    fi
  fi
}

if [[ "$action" == "submitted" ]] && [[ "$state" == "approved" ]]; then
  label_when_approved
else
  echo "Ignoring event ${action}/${state}"
fi
