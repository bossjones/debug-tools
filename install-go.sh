#!/bin/bash

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-go.sh - Install Go
#
# usage: install-go.sh
#
# Copyright (c) 2017, 2018 Takeshi Yonezu
# All Rights Reserved.
#-----------------------------------------------------------------------

logmsg() {
  echo ">>> $1"
}

#
# Install Go
#
VERSION=1.15.2
OS=$(uname -s)
ARCH=$(uname -m)
_whoami=$(whoami)

logmsg ">>> Install Go ${VERSION}"

case ${OS} in
  Linux)  OS=linux;;
  Darwin) OS=darwin;;
  *) echo "${OS}-${ARCH} does'nt supported yet."; exit 1;;
esac

case ${ARCH} in
  x86_64) ARCH=amd64;;
  armv7l) ARCH=armv6l;;
  *) echo "${OS}-${ARCH} does'nt supported yet."; exit 1;;
esac

cd /var/tmp

wget -N https://storage.googleapis.com/golang/go$VERSION.$OS-$ARCH.tar.gz

set -x

echo "[check] ${OS} = Linux"

if [ "${OS}" = "Linux" ]; then
  export _whoami=$(whoami)
  sudo mkdir -p /usr/local/go || true
  sudo chown -Rv ${_whoami}:${_whoami} /usr/local/go
  echo "[running] sudo tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz"
  sudo tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
  sudo chown -Rv ${_whoami}:${_whoami} /usr/local/go
else
  tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
fi

rm go$VERSION.$OS-$ARCH.tar.gz

cat >>~/.bashrc <<EOF
export GOPATH=/usr/local
export GOROOT=/usr/local/go
export PATH=\$PATH:\$GOROOT/bin
EOF

set +x

exit 0
