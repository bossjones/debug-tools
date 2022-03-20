#!/bin/bash

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install ctop
# https://github.com/bcicen/ctop/releases

CTOP_VERSION=0.7.6

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

set -x
curl -L https://github.com/bcicen/ctop/releases/download/${CTOP_VERSION}/ctop-${CTOP_VERSION}-${SYSTEM}-${HARDWARE} -o /usr/local/bin/ctop
set +x

chmod +x /usr/local/bin/ctop

exit 0
