#!/bin/bash

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-jid.sh - Install jid
#
# usage: install-jid.sh NON_ROOT_USER (use a non root user on your file system, eg install-jid.sh vagrant)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------
# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-jid.sh

# Install jid
# https://github.com/simeji/jid/releases/download/v0.7.6/jid_linux_amd64.zip

set -e



logmsg() {
  echo ">>> $1"
}


_user=$1

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install jid
# https://github.com/kubebox/kubebox/releases

if [[ "${_user}x" = "x" ]]; then
  echo "Please set a user, using install-jid.sh <USER>"
  exit 1
else
  NON_ROOT_USER=${_user}
fi

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

export URL="https://github.com/simeji/jid/releases/download/v${JID_VERSION}/jid_${SYSTEM}_${HARDWARE}.zip"

echo " [install-jid] generated url: ${URL}"
echo " [install-jid] hardcoded url: https://github.com/simeji/jid/releases/download/v0.7.6/jid_linux_amd64.zip"

curl -L "${URL}" > /tmp/jid_${SYSTEM}_${HARDWARE}.zip

# https://github.com/simeji/jid/releases/download/v0.7.6/jid_linux_amd64.zip

unzip /tmp/jid_${SYSTEM}_${HARDWARE}.zip -d /usr/local/bin
chmod +x /usr/local/bin/jid

sudo chmod +x /usr/local/bin/jid
sudo chown ${NON_ROOT_USER}:${NON_ROOT_USER} /usr/local/bin/jid

exit 0
