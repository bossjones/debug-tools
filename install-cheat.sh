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

CHEAT_VERSION=4.2.2

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

[ ! -f "${HOME}/.config/cheat/conf.yml" ] && mkdir -p ~/.config/cheat

set -x
[ ! -d "${HOME}/.config/cheat/cheatsheets/community" ] && mkdir -p ~/.config/cheat/cheatsheets || true; git clone https://github.com/cheat/cheatsheets ~/.config/cheat/cheatsheets/community || pushd ~/.config/cheat/cheatsheets/community;git pull;popd

cat <<'EOF' > ~/.config/cheat/conf.yml
---
# The editor to use with 'cheat -e <sheet>'. Defaults to $EDITOR or $VISUAL.
editor: vim

# Should 'cheat' always colorize output?
colorize: true

# Which 'chroma' colorscheme should be applied to the output?
# Options are available here:
#   https://github.com/alecthomas/chroma/tree/master/styles
style: monokai

# Which 'chroma' "formatter" should be applied?
# One of: "terminal", "terminal256", "terminal16m"
formatter: terminal16m

# Through which pager should output be piped? (Unset this key for no pager.)
pager: less -FRX

# The paths at which cheatsheets are available. Tags associated with a cheatpath
# are automatically attached to all cheatsheets residing on that path.
#
# Whenever cheatsheets share the same title (like 'tar'), the most local
# cheatsheets (those which come later in this file) take precedent over the
# less local sheets. This allows you to create your own "overides" for
# "upstream" cheatsheets.
#
# But what if you want to view the "upstream" cheatsheets instead of your own?
# Cheatsheets may be filtered via 'cheat -t <tag>' in combination with other
# commands. So, if you want to view the 'tar' cheatsheet that is tagged as
# 'community' rather than your own, you can use: cheat tar -t community
cheatpaths:

  # Paths that come earlier are considered to be the most "global", and will
  # thus be overridden by more local cheatsheets. That being the case, you
  # should probably list community cheatsheets first.
  #
  # Note that the paths and tags listed below are placeholders. You may freely
  # change them to suit your needs.
  #
  # Community cheatsheets must be installed separately, though you may have
  # downloaded them automatically when installing 'cheat'. If not, you may
  # download them here:
  #
  # https://github.com/cheat/cheatsheets
  #
  # Once downloaded, ensure that 'path' below points to the location at which
  # you downloaded the community cheatsheets.

  - name: community
    path: /home/CHANGE_ME/.config/cheat/cheatsheets/community
    tags: [ community ]
    readonly: true

  # If you have personalized cheatsheets, list them last. They will take
  # precedence over the more global cheatsheets.

  # While it requires no configuration here, it's also worth noting that
  # 'cheat' will automatically append directories named '.cheat' within the
  # current working directory to the 'cheatpath'. This can be very useful if
  # you'd like to closely associate cheatsheets with, for example, a directory
  # containing source code.
  #
  # Such "directory-scoped" cheatsheets will be treated as the most "local"
  # cheatsheets, and will override less "local" cheatsheets. Likewise,
  # directory-scoped cheatsheets will always be editable ('readonly: false').
EOF

sed -i "s,CHANGE_ME,${_user},g" ~/.config/cheat/conf.yml
mkdir -p ~/.local/bin
wget -O ~/.local/bin/cheatsheets https://raw.githubusercontent.com/cheat/cheat/master/scripts/git/cheatsheets
chmod +x ~/.local/bin/cheatsheets

cd -

logmsg ">>> testing cmd: cheat cp"
cheat cp

set +x

exit 0
