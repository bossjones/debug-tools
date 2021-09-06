#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-vim.sh - Install vim
#
# usage: install-vim.sh
# https://github.com/gpakosz/.vim
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


git clone git@github.com:bossjones/.vim.git ~/dev/bossjones/oh-my-vim || true
ln -v -s -f ~/dev/bossjones/oh-my-vim/.vim.conf ~/.vim.conf || true
cp -av ~/dev/bossjones/oh-my-vim/.vim.conf.local ~/.vim.conf.local || true


cd ~/dev/bossjones/oh-my-vim/
git remote add upstream git@github.com:gpakosz/.vim.git || true
git upstream https://github.com/gpakosz/.vim.git || true
cd -

