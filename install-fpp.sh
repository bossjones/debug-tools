#!/bin/bash

set -x

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-fpp.sh - Install Facebook path picker
#
# usage: install-fpp.sh
#
# Copyright (c) 2022 bossjones
# All Rights Reserved.
#-----------------------------------------------------------------------

logmsg() {
  echo ">>> $1"
}

sudo apt-get install xclip urlview -y

logmsg ">>> Install fpp ${VERSION}"
cd /var/tmp
git clone https://github.com/facebook/PathPicker.git || true
cd PathPicker/debian
./package.sh
# ls ../fpp_0.7.2_noarch.deb
pwd
cd -

sudo dpkg -i /var/tmp/PathPicker/debian/../pathpicker_0.9.2_all.deb

exit 0
