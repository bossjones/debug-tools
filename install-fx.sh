#!/bin/bash

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-fx.sh - Install fx
#
# usage: install-fx.sh NON_ROOT_USER (use a non root user on your file system, eg install-fx.sh vagrant)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------
# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-fx.sh

# Install fx
# https://github.com/antonmedv/fx

set -e

echo " [install-fx] see https://github.com/antonmedv/fx"


logmsg() {
  echo ">>> $1"
}


npm install -g fx


exit 0
