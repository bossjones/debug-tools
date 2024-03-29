#!/bin/bash

set -exu
set -o pipefail

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-neovim-config.sh - Install neovim-config ( this one does it ALL )
#
# usage: install-neovim-config.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------


logmsg() {
  echo ">>> $1"
}

function command-exists() {
    command -v "${1}" >/dev/null 2>&1 || { echo >&2 "I require ${1} but it's not installed.  Aborting."; return 1; }
}


_user="${1}"

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install neovim-config
# https://github.com/neovim-config/neovim-config/releases

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
    if [[ -f $(which apt-get) ]]; then
      pip3 install pynvim
      pip3 install jedi
      pip3 install vim-vint
      /usr/local/bin/install-ctags.sh
      /usr/local/bin/install-fonts.sh
      pip3 install pylint
      pip3 install flake8
      pip3 install autoflake
      /usr/local/bin/setup-neovim.sh
    fi
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
elif [ "${SYSTEM}" = "Darwin" ]; then
  if [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="darwin"
    HARDWARE="amd64"
    if [[ -f $(which brew) ]]; then
      pip3 install pynvim
      pip3 install jedi
      pip3 install vim-vint
      brew install ctags
    fi
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
else
  echo "This platform does'nt suppot yet!!"
  exit 1
fi

exit 0
