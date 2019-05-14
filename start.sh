#!/bin/bash
set -e

# turn on bash's job control
set -m

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


if [ -n "$VSTS_AGENT_NAME" ]
then
  export VSTS_AGENT=$VSTS_AGENT_NAME
else
  export VSTS_AGENT="docker-$(cat "/etc/hostname")"
fi

/vsts-agent-linux/bin/Agent.Listener configure --unattended \
  --agent "$VSTS_AGENT" \
  --url "https://dev.azure.com/$VSTS_ACCOUNT/" \
  --auth PAT \
  --token "$(cat "$VSTS_TOKEN_FILE")" \
  --pool "default" \
  --work "/vsts-agent-linux/_work" \
  --replace 



# Start the primary process and put it in the background
/usr/bin/dockerd-ce &

# Start the helper process
/vsts-agent-linux/bin/Agent.Listener run