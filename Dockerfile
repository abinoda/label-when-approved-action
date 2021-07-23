FROM alpine:3.10.3

LABEL "com.github.actions.name"="Label approved pull requests"
LABEL "com.github.actions.description"="Auto-label pull requests that have a specified number of approvals"
LABEL "com.github.actions.icon"="tag"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"
LABEL repository="http://github.com/pullreminders/label-when-approved-action"
LABEL homepage="http://github.com/pullreminders/label-when-approved-action"
LABEL maintainer="Abi Noda <abi@pullreminders.com>"

RUN apk add --no-cache bash curl jq grep

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
