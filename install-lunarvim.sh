#!/bin/bash

set -exu
set -o pipefail

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-lunarvim.sh - Install lunarvim ( this one does it ALL )
#
# usage: install-lunarvim.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------


logmsg() {
  echo ">>> $1"
}

function command-exists() {
    command -v "${1}" >/dev/null 2>&1 || { echo >&2 "I require ${1} but it's not installed.  Aborting."; return 1; }
}


_user="${1}"

npm install -g diff-so-fancy
# SOURCE: https://github.com/tkyonezu/Linux-tools/blob/98a373f3756fe9e27d27a8c3cf7d39fd447ea5c1/install-ctop.sh

# Install lunarvim
# https://github.com/lunarvim/lunarvim/releases

if [[ "${_user}x" = "x" ]]; then
  NON_ROOT_USER=nobody
else
  NON_ROOT_USER=${_user}
fi

HARDWARE=$(uname -m)
SYSTEM=$(uname -s)


if [ "${SYSTEM}" = "Linux" ]; then
  if [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="linux"
    HARDWARE="amd64"
    if [[ -f $(which apt-get) ]]; then
      pip3 install pynvim
      pip3 install jedi
      pip3 install vim-vint
      /usr/local/bin/install-ctags.sh
      /usr/local/bin/install-fonts.sh
      pip3 install pylint
      pip3 install flake8
      pip3 install wheel
      pip3 install autoflake
      sudo apt install lua5.3 -y
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
      source $HOME/.cargo/env
    fi
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
elif [ "${SYSTEM}" = "Darwin" ]; then
  if [ "${HARDWARE}" = "x86_64" ]; then
    SYSTEM="darwin"
    HARDWARE="amd64"
    if [[ -f $(which brew) ]]; then
      pip3 install pynvim
      pip3 install jedi
      pip3 install vim-vint
      brew install ctags
    fi
  else
    echo "This platform does'nt suppot yet!!"
    exit 1
  fi
else
  echo "This platform does'nt suppot yet!!"
  exit 1
fi

cat <<EOF >~/rust.bash
if [ -d "\$HOME/.cargo/bin" ]; then
  export PATH=\$HOME/.cargo/bin:$PATH
fi
EOF
cat ~/rust.bash

# Setting up environment variables
set -x
if ! grep -q 'source ~/rust.bash' ~/.bash_profile ; then\
    echo 'source ~/rust.bash'  | tee -a ~/.bash_profile  ;\
    source ~/rust.bash ;\
fi
if ! grep -q 'source ~/rust.bash' ~/.bashrc ; then\
    echo 'source ~/rust.bash'  | tee -a ~/.bashrc  ;\
    source ~/rust.bash ;\
fi

exec "$SHELL"

set +x
bash <(curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh)

mkdir fonts || true
cd fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Ubuntu.zip
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/UbuntuMono.zip
unzip Ubuntu.zip
unzip UbuntuMono.zip
rm *.zip
mkdir -p ~/.local/share/fonts || true
mv -fv *.ttf ~/.local/share/fonts/


echo "Installing language servers"
# https://github.com/LunarVim/LunarVim
# # nvim +PlugInstall +qall
# Enter :LspInstall followed by <TAB> to see your options for LSP

# Enter :TSInstall followed by <TAB> to see your options for syntax highlighting
# lvim +LvimUpdate +q

exit 0

