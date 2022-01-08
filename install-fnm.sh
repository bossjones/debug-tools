#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-rbenv.sh - Install rbenv
#
# usage: install-rbenv.sh
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------

logmsg() {
  echo ">>> $1"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[[ -f ${_DIR}/install-config ]] && echo "This file exists! - ${_DIR}/install-config"

source ${_DIR}/install-config

curl -fsSL https://github.com/Schniz/fnm/raw/master/.ci/install.sh | bash

# SOURCE: https://github.com/Schniz/fnm
if [ -n "$(which fnm)" ]; then
    eval "$(fnm env)"
    if [ "$(fnm ls | grep -i ${NODE_VERSION_TO_INSTALL} | wc -l)" = "0" ]; then
      fnm install ${NODE_VERSION_TO_INSTALL} || true
      fnm use ${NODE_VERSION_TO_INSTALL} || true
      fnm default ${NODE_VERSION_TO_INSTALL} || true
      fnm current || true
      npm install -g pure-prompt || true
      npm install -g pretty-time-zsh || true
    fi
fi
