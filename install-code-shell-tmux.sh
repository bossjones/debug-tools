#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-code-shell.sh - Install code-shell
#
# usage: install-code-shell.sh
# https://medium.com/@joaomoreno/persistent-terminal-sessions-in-vs-code-8fc469ed6b41
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------

# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi
# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi
# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi
# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi
# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi
# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi
# HOTFIX: https://dev.to/ajkerrigan/bring-your-vim-tmux-navigation-reflexes-to-vs-code-3abi

logmsg() {
    echo ">>> $1"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# [[ -f ${_DIR}/install-config ]] && echo "This file exists! - ${_DIR}/install-config" || true

# source ${_DIR}/install-config

mkdir -p ~/.bin/ || true
### Setting environment variables
echo "Writing code-shell to ~/.bin/code-shell ..."
bash -c 'cat >> ~/.bin/code-shell << \EOF
    #!/bin/sh
    SESSION="vscode`pwd | md5`"
    tmux attach-session -d -t $SESSION || tmux new-session -s $SESSION
EOF'

chmod +x ~/.bin/code-shell

echo "Don't forget to update vscode settings.json to use: \"terminal.integrated.shell.osx\": \"/Users/malcolm/.bin/code-shell\""
