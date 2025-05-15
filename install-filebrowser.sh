#!/bin/bash

set -e

#  filebrowser -a 0.0.0.0 -r ./farming -p 6060


#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-kubebox.sh - Install kubebox
#
# usage: install-kubebox.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------


logmsg() {
  echo ">>> $1"
}


_user=$1

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install kubebox
# https://github.com/astefanutti/kubebox/releases

if [[ "${_user}x" = "x" ]]; then
  NON_ROOT_USER=nobody
else
  NON_ROOT_USER=${_user}
fi

HARDWARE=$(uname -m)
SYSTEM=$(uname -s)

if [ "${SYSTEM}" = "Linux" ]; then
  if [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="linux"
    HARDWARE="amd64"
    URL="https://github.com/astefanutti/kubebox/releases/download/v0.9.0/kubebox-linux"
    FNAME="kubebox-linux"
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
elif [ "${SYSTEM}" = "Darwin" ]; then
  if [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="darwin"
    HARDWARE="amd64"
    URL="https://github.com/astefanutti/kubebox/releases/download/v0.8.0/kubebox-macos"
    FNAME="kubebox-macos"
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
else
  echo "This platform does'nt suppot yet!!"
  exit 1
fi

cd /usr/local/bin

if [ ! -f /usr/local/bin/kubebox ]; then
  curl -Lo kubebox ${URL} && chmod +x kubebox
fi

sudo chmod +x /usr/local/bin/kubebox
sudo chown ${NON_ROOT_USER}:${NON_ROOT_USER} /usr/local/bin/kubebox


cd -

exit 0
