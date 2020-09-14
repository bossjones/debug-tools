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

export PATH="${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:$PATH"

curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash

curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash

git clone https://github.com/rbenv/rbenv-vars.git ${RBENV_ROOT}/plugins/rbenv-vars  || echo "already cloned"
git clone https://github.com/rbenv/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build  || echo "already cloned"
git clone https://github.com/rbenv/rbenv-default-gems.git ${RBENV_ROOT}/plugins/default-gems  || echo "already cloned"
git clone https://github.com/rbenv/rbenv-installer.git ${RBENV_ROOT}/plugins/rbenv-installer  || echo "already cloned"
git clone https://github.com/rkh/rbenv-update.git ${RBENV_ROOT}/plugins/rbenv-update  || echo "already cloned"
git clone https://github.com/rkh/rbenv-whatis.git ${RBENV_ROOT}/plugins/rbenv-whatis  || echo "already cloned"
git clone https://github.com/rkh/rbenv-use.git ${RBENV_ROOT}/plugins/rbenv-use  || echo "already cloned"
git clone https://github.com/tpope/rbenv-ctags.git ${RBENV_ROOT}/plugins/rbenv-ctags  || echo "already cloned"
git clone https://github.com/rbenv/rbenv-each.git ${RBENV_ROOT}/plugins/rbenv-each  || echo "already cloned"
git clone https://github.com/tpope/rbenv-aliases.git ${RBENV_ROOT}/plugins/rbenv-aliases  || echo "already cloned"

if [ -e ${RBENV_ROOT} ]; then
  export PATH="${RBENV_ROOT}/shims:$PATH"
fi
if [[ -x $(which -p rbenv) ]]; then
  eval "$(rbenv init -)"
fi

echo 'gem: --no-rdoc --no-ri' >> /.gemrc

rbenv install ${RBENV_VERSION}
rbenv global ${RBENV_VERSION}
gem install pry bundler ruby-debug-ide debase rcodetools rubocop fastri htmlbeautifier hirb gem-ctags travis excon pry-doc tmuxinator solargraph