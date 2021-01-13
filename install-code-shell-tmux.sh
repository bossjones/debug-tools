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

logmsg() {
    echo ">>> $1"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[[ -f ${_DIR}/install-config ]] && echo "This file exists! - ${_DIR}/install-config"

source ${_DIR}/install-config


### Setting environment variables
echo "Writing code-shell to ~/.bin/code-shell ..."
bash -c 'cat >> ~/.bin/code-shell << \EOF
    #!/bin/sh
    SESSION="vscode`pwd | md5`"
    tmux attach-session -d -t $SESSION || tmux new-session -s $SESSION
EOF'

echo "Don't forget to update vscode settings.json to use: \"terminal.integrated.shell.osx\": \"/Users/malcolm/.bin/code-shell\""
