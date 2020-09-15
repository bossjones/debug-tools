#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-asdf.sh - Install asdf
#
# usage: install-asdf.sh
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------

logmsg() {
  echo ">>> $1"
}

asdf_add_or_ignore() {
  echo ">>> Adding asdf plugin: $1"
  asdf plugin-add $1 $2 || echo "plugin already loaded"
}

_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

[[ -f ${_DIR}/install-config ]] && echo "This file exists! - ${_DIR}/install-config"
source ${_DIR}/install-config

git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0 || true

echo "[asdf] enable"
. $HOME/.asdf/asdf.sh

echo " [asdf] compile dependencies"
/usr/local/bin/install-compile-tools.sh

# asdf plugin-add 1password https://github.com/samtgarson/asdf-1password.git # 1.6.0 
# asdf plugin add goss https://github.com/raimon49/asdf-goss.git # 0.3.13 
asdf_add_or_ignore hadolint https://github.com/looztra/asdf-hadolint # 1.18.0
asdf_add_or_ignore fd # 8.1.1 
asdf_add_or_ignore tmux https://github.com/aphecetche/asdf-tmux.git # 2.9a
asdf_add_or_ignore helm https://github.com/Antiarchitect/asdf-helm.git # 3.3.1 
asdf_add_or_ignore jsonnet https://github.com/Banno/asdf-jsonnet.git # 0.16.0
asdf_add_or_ignore k9s https://github.com/looztra/asdf-k9s # 0.21.7 
asdf_add_or_ignore kubectl https://github.com/Banno/asdf-kubectl.git # 1.18.6
asdf_add_or_ignore kubectx # 0.9.1
asdf_add_or_ignore kubeval https://github.com/stefansedich/asdf-kubeval # 0.15.0 
asdf_add_or_ignore neovim # 0.4.4 
asdf_add_or_ignore packer https://github.com/Banno/asdf-hashicorp.git # 1.6.2
asdf_add_or_ignore terraform https://github.com/Banno/asdf-hashicorp.git # 0.13.2
asdf_add_or_ignore vault https://github.com/Banno/asdf-hashicorp.git # 1.5.3
asdf_add_or_ignore poetry https://github.com/crflynn/asdf-poetry.git # 1.0.10
asdf_add_or_ignore yq https://github.com/sudermanjr/asdf-yq.git # 3.2.3 

# asdf install goss 0.3.13
# asdf global goss 0.3.13

asdf install fd 8.1.1
asdf global fd 8.1.1

asdf install tmux 2.9a
asdf global tmux 2.9a

asdf install helm 3.3.1
asdf global helm 3.3.1

asdf install jsonnet 0.16.0
asdf global jsonnet 0.16.0

asdf install k9s 0.21.7
asdf global k9s 0.21.7

asdf install kubectl 1.18.6
asdf global kubectl 1.18.6

asdf install kubectx 0.9.1
asdf global kubectx 0.9.1

asdf install kubeval 0.15.0 
asdf global kubeval 0.15.0 

asdf install neovim 0.4.4
asdf global neovim 0.4.4

asdf install packer 1.6.2
asdf global packer 1.6.2

asdf install terraform 0.13.2
asdf global terraform 0.13.2

asdf install vault 1.5.3
asdf global vault 1.5.3

asdf install poetry 1.0.10
asdf global poetry 1.0.10

asdf install yq 3.2.3
asdf global yq 3.2.3

echo " [fd] testing"
fd --help

echo " [tmux] testing"
tmux -V

echo " [helm] testing"
helm --help

echo " [helm] jsonnet"
jsonnet --help

echo " [k9s] testing"
k9s --help

echo " [kubectl] testing"
kubectl version

echo " [kubectx] testing"
kubectx --help

echo " [kubeval] testing"
kubeval --version

echo " [neovim] testing"
nvim --version

echo " [packer] testing"
packer --version

echo " [terraform] testing"
terraform --version

echo " [vault] testing"
vault --version

echo " [poetry] testing"
poetry --version

echo " [yq] testing"
yq --version