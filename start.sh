#!/bin/bash
set -e


if [ -z "$VSTS_ACCOUNT" ]; then
  echo 1>&2 error: missing VSTS_ACCOUNT environment variable
  exit 1
fi


if [ -z "$VSTS_TOKEN_FILE" ]; then
  if [ -z "$VSTS_TOKEN" ]; then
    echo 1>&2 error: missing VSTS_TOKEN environment variable
    exit 1
  fi
  VSTS_TOKEN_FILE=/vsts-agent-linux/.token
  echo -n $VSTS_TOKEN > "$VSTS_TOKEN_FILE"
fi
unset VSTS_TOKEN


if [ -n "$VSTS_AGENT" ]; then
  export VSTS_AGENT="$(eval echo $VSTS_AGENT)"
fi

/vsts-agent-linux/bin/Agent.Listener configure --unattended \
  --agent "docker-$(cat "/etc/hostname")" \
  --url "https://dev.azure.com/$VSTS_ACCOUNT/" \
  --auth PAT \
  --token "$(cat "$VSTS_TOKEN_FILE")" \
  --pool "default" \
  --work "/vsts-agent-linux/_work" \
  --replace 

/vsts-agent-linux/bin/Agent.Listener run