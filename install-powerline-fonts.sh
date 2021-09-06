#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-tmux.sh - Install tmux
#
# usage: install-tmux.sh
# https://github.com/gpakosz/.tmux
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------

logmsg() {
    echo ">>> $1"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# [[ -f ${_DIR}/install-config ]] && echo "This file exists! - ${_DIR}/install-config"

# source ${_DIR}/install-config


git clone git@github.com:bossjones/.tmux.git ~/dev/bossjones/oh-my-tmux || cd ~/dev/bossjones/oh-my-tmux && git pull --rebase || true
ln -v -s -f ~/dev/bossjones/oh-my-tmux/.tmux.conf ~/.tmux.conf || true
cp -av ~/dev/bossjones/oh-my-tmux/.tmux.conf.local ~/.tmux.conf.local || true


cd ~/dev/bossjones/oh-my-tmux/
git remote add upstream git@github.com:gpakosz/.tmux.git || true
# git upstream https://github.com/gpakosz/.tmux.git || true
cd -
