#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-zsh-pure.sh - Install zsh-pure
#
# usage: install-zsh-pure.sh
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

# NOTE: these should exist # assumptions: fnm, fzf, and more

# verify pyenv is installed
pyenv which pip
# Example output # /home/pi/.pyenv/versions/3.9.0/bin/pip

pyenv rehash

sudo apt-get install -y fzf jq rbenv silversearcher-ag tmux tree direnv

mkdir -p ~/dev/bossjones || true
git clone git@github.com:bossjones/ansible-role-oh-my-zsh.git ~/dev/bossjones/ansible-role-oh-my-zsh
cd ~/dev/bossjones/ansible-role-oh-my-zsh
python3 -m venv .venv
source .venv/bin/activate
python3 -c "import sys;print(sys.executable)"
pip install -U pip wheel setuptools
pip install pip-tools pipdeptree --upgrade
python --version
pip install -r requirements.txt

make run-ubuntu-pure
