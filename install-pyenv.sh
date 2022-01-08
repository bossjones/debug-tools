#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-pyenv.sh - Install Pyenv
#
# usage: install-pyenv.sh
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


#
# Install Pyenv
#
VERSION=1.11.2
OS=$(uname -s)
ARCH=$(uname -m)
UNAME_A=$(uname -a)



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


if [[ "$(echo ${UNAME_A} | grep -i 'ubuntu' | wc -l)" = "1" ]]; then
    logmsg ">>> Installing prereqs Pyenv ${VERSION}"
    # https://github.com/pyenv/pyenv/wiki/Common-build-problems
    sudo apt-get update && \
    sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
    sudo apt-get install -y --no-install-recommends \
        make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
        libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev \
        libxml2-dev libxmlsec1-dev libffi-dev \
        ca-certificates && \
    sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python-openssl git
fi

logmsg ">>> Install Pyenv ${VERSION}"
echo ${OS}
case ${OS} in
  *inux)
    sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends git ca-certificates curl && \
    curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash && \
    git clone https://github.com/yyuu/pyenv-pip-rehash.git $(pyenv root)/plugins/pyenv-pip-rehash

    echo -e "${PYENV_VERSIONS_TO_INSTALL}" > ~/python-versions.txt
    pyenv update && \
            xargs -P 4 -n 1 pyenv install < ~/python-versions.txt && \
            pyenv global $(pyenv versions --bare) && \
            find $PYENV_ROOT/versions -type d '(' -name '__pycache__' -o -name 'test' -o -name 'tests' ')' -exec rm -rfv '{}' + && \
            find $PYENV_ROOT/versions -type f '(' -name '*.py[co]' -o -name '*.exe' ')' -exec rm -fv '{}' + && \
            cat ~/python-versions.txt | tee $PYENV_ROOT/version

    ;;
  Darwin) OS=darwin;;
  *) echo "${OS}-${ARCH} does'nt supported yet."; exit 1;;
esac

cat <<EOF >$PYENV_ROOT/pyenv.bash
if [ -e \$PYENV_ROOT ]; then
  export PYENV_ROOT=~/.pyenv
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "\$(pyenv init --path)"
  eval "\$(pyenv init -)"
  pyenv virtualenvwrapper_lazy
fi
EOF
cat $PYENV_ROOT/pyenv.bash


# Setting up environment variables

if ! grep -q 'source $PYENV_ROOT/pyenv.bash' ~/.bash_profile ; then\
    echo 'source $PYENV_ROOT/pyenv.bash'  | tee -a ~/.bash_profile  ;\
    source $PYENV_ROOT/pyenv.bash ;\
fi

# if ! grep -q 'source $PYENV_ROOT/pyenv.bash' ~/.zsh.d/before/conda.zsh; then\
#     echo 'source $PYENV_ROOT/pyenv.bash'  | tee -a ~/.zsh.d/before/conda.zsh ;\
#     source $PYENV_ROOT/pyenv.bash ;\
# fi

exec "$SHELL"



exit 0
