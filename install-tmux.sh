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

install-asdf.sh

logmsg() {
    echo ">>> $1"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# [[ -f ${_DIR}/install-config ]] && echo "This file exists! - ${_DIR}/install-config"

# source ${_DIR}/install-config

mkdir -p ~/dev/bossjones || true
git clone git@github.com:bossjones/.tmux.git ~/dev/bossjones/oh-my-tmux || true
ln -v -s -f ~/dev/bossjones/oh-my-tmux/.tmux.conf ~/.tmux.conf || true
cp -av ~/dev/bossjones/oh-my-tmux/.tmux.conf.local ~/.tmux.conf.local || true


cd ~/dev/bossjones/oh-my-tmux/
git remote add upstream git@github.com:gpakosz/.tmux.git || true
git upstream https://github.com/gpakosz/.tmux.git || true
cd -

mkdir -p ~/.bin || true
curl -L 'https://raw.githubusercontent.com/junegunn/fzf/master/bin/fzf-tmux' > ~/.bin/fzf-tmux
chmod +x ~/.bin/fzf-tmux

echo "Setting ~/.bin/tmux_colors.sh..."
bash -c 'cat >> ~/.bin/tmux_colors.sh << \EOF
    #! /bin/bash

    for i in {0..255} ; do
        printf "\x1b[38;5;${i}mcolour${i}\n"
    done
EOF'


git clone git@github.com:kevinhwang91/fzf-tmux-script.git ~/dev/fzf-tmux-script || cd ~/dev/fzf-tmux-script && git pull --rebase || true
cp -av ~/dev/fzf-tmux-script/panes/fzf-panes.tmux ~/.bin/fzf-panes.tmux
cp -av ~/dev/fzf-tmux-script/popup/fzfp ~/.bin/fzfp
