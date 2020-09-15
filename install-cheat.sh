#!/bin/bash

set -e

# cheat-darwin-amd64.gz
# 2.55 MB
# cheat-linux-386.gz
# 2.32 MB
# cheat-linux-amd64.gz
# 2.5 MB
# cheat-linux-arm5.gz
# 2.4 MB
# cheat-linux-arm6.gz
# 2.39 MB
# cheat-linux-arm7.gz
# 2.39 MB
# cheat-windows-amd64.exe.zip
# 2.56 MB
# Source code
# (zip)
# Source code
# (tar.gz)

# https://github.com/cheat/cheat/releases/download/4.1.0/cheat-linux-amd64.gz

# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install cheat
# https://github.com/cheat/cheat/releases

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

# cheat-darwin-amd64.gz
# 2.55 MB
# cheat-linux-386.gz
# 2.32 MB
# cheat-linux-amd64.gz
# 2.5 MB
# cheat-linux-arm5.gz
# 2.4 MB
# cheat-linux-arm6.gz
# 2.39 MB
# cheat-linux-arm7.gz
# 2.39 MB
# cheat-windows-amd64.exe.zip
# 2.56 MB
# Source code
# (zip)
# Source code
# (tar.gz)
cd /usr/local/bin


curl -L "https://github.com/cheat/cheat/releases/download/${CHEAT_VERSION}/cheat-${SYSTEM}-${HARDWARE}.gz" > cheat-${SYSTEM}-${HARDWARE}.gz
gzip -d cheat-${SYSTEM}-${HARDWARE}.gz
mv cheat-${SYSTEM}-${HARDWARE} cheat
# https://github.com/cheat/cheat/releases/download/4.1.0/cheat-linux-amd64.gz
chmod +x /usr/local/bin/cheat

cd -

exit 0
