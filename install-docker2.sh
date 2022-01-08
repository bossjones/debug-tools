#!/bin/bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-docker2.sh - Install docker2
#
# usage: install-docker2.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------


logmsg() {
  echo ">>> $1"
}


_user=$1

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install cheat
# https://github.com/cheat/cheat/releases

if [[ "${_user}x" = "x" ]]; then
  NON_ROOT_USER=nobody
else
  NON_ROOT_USER=${_user}
fi

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
# # run docker commands as vagrant user (sudo not required)
sudo usermod -aG docker $NON_ROOT_USER
# apt-get install -y apt-transport-https curl



exit 0
