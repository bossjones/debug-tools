#!/usr/bin/env bash

# https://unix.stackexchange.com/questions/424492/how-to-define-a-shell-script-to-be-sourced-not-run/424495
# How to define a shell script to be sourced not run
if [ "${BASH_SOURCE[0]}" -ef "$0" ]
then
    echo "Hey, you should source this script, not execute it!"
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update && \
    sudo apt-get install -y locales ca-certificates && \
    sudo localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
export LANG=en_US.UTF-8
