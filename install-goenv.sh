#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-goenv.sh - Install goenv
#
# usage: install-goenv.sh
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

git clone https://github.com/syndbg/goenv.git ~/.goenv || true

# BASH
echo 'export GOENV_ROOT="$HOME/.goenv"' > ~/goenv.bash
echo 'export PATH="$GOENV_ROOT/bin:$PATH"' >> ~/goenv.bash
echo 'eval "$(goenv init -)"' >> ~/goenv.bash
echo 'export PATH="$GOROOT/bin:$PATH"' >> ~/goenv.bash
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/goenv.bash
# Setting up environment variables
set -x
if ! grep -q 'source ~/goenv.bash' ~/.bash_profile ; then\
    echo 'source ~/goenv.bash'  | tee -a ~/.bash_profile  ;\
    source ~/goenv.bash ;\
fi
if ! grep -q 'source ~/goenv.bash' ~/.bashrc ; then\
    echo 'source ~/goenv.bash'  | tee -a ~/.bashrc  ;\
    source ~/goenv.bash ;\
fi
set +x

if ! grep -q 'export GOENV_ROOT=$HOME/.goenv' ~/.zshenv ; then\
    echo 'export GOENV_ROOT=$HOME/.goenv'  | tee -a ~/.zshenv  ;\
    export GOENV_ROOT=$HOME/.goenv ;\
fi

if [ -d "/usr/local/go/bin" ]; then
  export PATH=/usr/local/go/bin:$PATH
fi
export PATH=$GOPATH/bin:$PATH
alias cdgo='CDPATH=.:$GOPATH/src/github.com:$GOPATH/src/golang.org:$GOPATH/src'

if [ -d ~/.goenv ]; then
  export GOENV_ROOT="$HOME/.goenv"
  export PATH="$GOENV_ROOT/bin:$PATH"
  eval "$(goenv init -)"
  export PATH="$GOROOT/bin:$PATH"
  export PATH="$PATH:$GOPATH/bin"
fi

exec "$SHELL"

if [ -d "/usr/local/go/bin" ]; then
  export PATH=/usr/local/go/bin:$PATH
fi
export PATH=$GOPATH/bin:$PATH
alias cdgo='CDPATH=.:$GOPATH/src/github.com:$GOPATH/src/golang.org:$GOPATH/src'

if [ -d ~/.goenv ]; then
  export GOENV_ROOT="$HOME/.goenv"
  export PATH="$GOENV_ROOT/bin:$PATH"
  eval "$(goenv init -)"
  export PATH="$GOROOT/bin:$PATH"
  export PATH="$PATH:$GOPATH/bin"
fi
goenv install 1.17.6

# See for more:
# https://github.com/syndbg/goenv/blob/master/INSTALL.md
