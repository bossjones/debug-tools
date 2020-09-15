#!/bin/bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-cheat.sh - Install cheat
#
# usage: install-cheat.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------

_user=$1

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install cheat
# https://github.com/cheat/cheat/releases

if [[ "${_user}x" = "x" ]]; then
  NON_ROOT_USER=nobody
else
  NON_ROOT_USER=${_user}
fi

CHEAT_VERSION=4.1.0

HARDWARE=$(uname -m)
SYSTEM=$(uname -s)

if [ "${SYSTEM}" = "Linux" ]; then
  if [ "${HARDWARE}" = "armv7l" ]; then
    SYSTEM="linux"
    HARDWARE="arm7"
  elif [ "${HARDWARE}" = "armv5tejl" ]; then
    SYSTEM="linux"
    HARDWARE="arm5"
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

cd /usr/local/bin

if [ ! -f /usr/local/bin/cheat ]; then
  curl -L "https://github.com/cheat/cheat/releases/download/${CHEAT_VERSION}/cheat-${SYSTEM}-${HARDWARE}.gz" > cheat-${SYSTEM}-${HARDWARE}.gz
  gzip -d cheat-${SYSTEM}-${HARDWARE}.gz
  mv cheat-${SYSTEM}-${HARDWARE} cheat
fi

sudo chmod +x /usr/local/bin/cheat
sudo chown ${NON_ROOT_USER}:${NON_ROOT_USER} /usr/local/bin/cheat

[ ! -f ~/.config/cheat ] && mkdir -p ~/.config/cheat; cheat --init > ~/.config/cheat/conf.yml

[ ! -d ~/.config/cheat/cheatsheets/community ] && mkdir -p ~/.config/cheat/cheatsheets; git clone https://github.com/cheat/cheatsheets ~/.config/cheat/cheatsheets/community

cd -

exit 0
