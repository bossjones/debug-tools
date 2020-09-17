#!/bin/bash

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-jid.sh

# Install jid
# https://github.com/simeji/jid/releases/download/v0.7.6/jid_linux_amd64.zip

JID_VERSION=0.7.6

HARDWARE=$(uname -m)
SYSTEM=$(uname -s)

if [ "${SYSTEM}" = "Linux" ]; then
  if [ "${HARDWARE}" = "armv7l" ]; then
    SYSTEM="linux"
    HARDWARE="arm"
  elif [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="linux"
    HARDWARE="amd64"
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
elif [ "${SYSTEM}" = "Darwin" ]; then
  if [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="darwin"
    HARDWARE="amd64"
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
else
  echo "This platform does'nt suppot yet!!"
  exit 1
fi

echo " [install-jid] generated url: https://github.com/simeji/jid/releases/download/v${JID_VERSION}/jid_${SYSTEM}-${HARDWARE}.zip"
echo " [install-jid] hardcoded url: https://github.com/simeji/jid/releases/download/v0.7.6/jid_linux_amd64.zip"

curl -L "https://github.com/simeji/jid/releases/download/v${JID_VERSION}/jid_${SYSTEM}-${HARDWARE}.zip" > /tmp/jid_${SYSTEM}-${HARDWARE}.zip

# https://github.com/simeji/jid/releases/download/v0.7.6/jid_linux_amd64.zip

unzip /tmp/jid_${SYSTEM}-${HARDWARE}.zip -d /usr/local/bin
chmod +x /usr/local/bin/jid

exit 0
