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

# install-asdf.sh

logmsg() {
    echo ">>> $1"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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

mkdir -p ~/.bin/ || true
git clone https://github.com/bossjones/fzf-tmux-script ~/dev/fzf-tmux-script || cd ~/dev/fzf-tmux-script && git pull --rebase || true
cp -av ~/dev/fzf-tmux-script/panes/fzf-panes.tmux ~/.bin/fzf-panes.tmux
cp -av ~/dev/fzf-tmux-script/popup/fzfp ~/.bin/fzfp
