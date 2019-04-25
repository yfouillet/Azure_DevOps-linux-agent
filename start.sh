#!/bin/bash
set -e


if [ -z "$VSTS_ACCOUNT" ]; then
  echo 1>&2 error: missing VSTS_ACCOUNT environment variable
  exit 1
fi

  if [ -z "$VSTS_TOKEN" ]; then
    echo 1>&2 error: missing VSTS_TOKEN environment variable
    exit 1
  fi

if [ -n "$VSTS_AGENT" ]; then
  export VSTS_AGENT="$(eval echo $VSTS_AGENT)"
fi

/vsts-agent-linux/bin/Agent.Listener configure --unattended \
  --agent "docker-$(cat "/etc/hostname")" \
  --url "https://dev.azure.com/$VSTS_ACCOUNT/" \
  --auth PAT \
  --token "$VSTS_TOKEN" \
  --pool "default" \
  --work "/vsts-agent-linux/_work" \
  --replace 

/vsts-agent-linux/bin/Agent.Listener run