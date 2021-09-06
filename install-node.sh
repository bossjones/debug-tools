#!/bin/bash

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-node.sh - Install Node.js
#
# usage: install-node.sh
#
# Copyright (c) 2018 Takeshi Yonezu
# All Rights Reserved.
#-----------------------------------------------------------------------

logmsg() {
  echo ">>> $1"
}

#
# Install Node.js
#
logmsg ">>> Install Node.js 14.x"

curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -

curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/yarnkey.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update && sudo apt-get install yarn -y


sudo apt-get install gcc g++ make -y
sudo apt-get install -y nodejs

npm install -g pure-prompt || true
npm install -g pretty-time-zsh || true

exit 0
