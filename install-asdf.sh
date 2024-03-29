#!/usr/bin/env bash

OS=$(uname -s)
ARCH=$(uname -m)
_whoami=$(whoami)

if [ "${OS}" = "Linux" ]; then
    # needed for ag
    echo "Linux detected"
    sudo apt-get install libpcre2-dev -y
    sudo apt-get install -y automake pkg-config libpcre3-dev zlib1g-dev liblzma-dev
    
    git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.9.0 || true
fi

set -x
echo "[asdf] enable"
export OPT_HOMEBREW="/opt/homebrew"
if [[ -s "$OPT_HOMEBREW"/bin/brew ]]; then
    eval "$($OPT_HOMEBREW/bin/brew shellenv)"
fi

if [[ -s "$HOMEBREW_PREFIX"/opt/asdf/libexec/asdf.sh ]]; then
    ASDF_DIR="${HOMEBREW_PREFIX}/opt/asdf/libexec"
    ASDF_COMPLETIONS="$ASDF_DIR/completions"
    . "$HOMEBREW_PREFIX"/opt/asdf/libexec/asdf.sh
    
    fpath=(${ASDF_DIR}/completions $fpath)
    # autoload -Uz compinit
    # compinit
elif [[ -s "$HOME/.asdf/asdf.sh" ]]; then
    . "$HOME"/.asdf/asdf.sh
fi
set +x

set -e

# asdf plugin-add 1password https://github.com/samtgarson/asdf-1password.git # 1.6.0
# asdf plugin add goss https://github.com/raimon49/asdf-goss.git # 0.3.13
asdf plugin-add hadolint https://github.com/looztra/asdf-hadolint # 1.18.0
asdf plugin add fd # 8.1.1
asdf plugin-add tmux https://github.com/aphecetche/asdf-tmux.git # 2.9a
asdf plugin-add helm https://github.com/Antiarchitect/asdf-helm.git # 3.3.1
asdf plugin-add jsonnet https://github.com/Banno/asdf-jsonnet.git # 0.16.0
asdf plugin-add k9s https://github.com/looztra/asdf-k9s # 0.21.7
asdf plugin-add kubectl https://github.com/Banno/asdf-kubectl.git # 1.18.6
asdf plugin add kubectx # 0.9.1
if [ "${OS}" = "Linux" ]; then
    asdf plugin-add kubeval https://github.com/stefansedich/asdf-kubeval # 0.15.0
fi
asdf plugin-add neovim # 0.4.4
asdf plugin-add packer https://github.com/Banno/asdf-hashicorp.git # 1.6.2
asdf plugin-add terraform https://github.com/Banno/asdf-hashicorp.git # 0.13.2
asdf plugin-add vault https://github.com/Banno/asdf-hashicorp.git # 1.5.3
asdf plugin-add poetry https://github.com/crflynn/asdf-poetry.git # 1.0.10
asdf plugin-add yq https://github.com/sudermanjr/asdf-yq.git # 3.2.3
asdf plugin add ag https://github.com/koketani/asdf-ag.git
asdf plugin-add aria2 https://github.com/asdf-community/asdf-aria2.git
asdf plugin-add argo https://github.com/sudermanjr/asdf-argo.git
asdf plugin-add dive https://github.com/looztra/asdf-dive
asdf plugin-add github-cli https://github.com/bartlomiejdanek/asdf-github-cli.git
asdf plugin add kompose
asdf plugin add mkcert
asdf plugin-add shellcheck
asdf plugin-add shfmt
asdf plugin-add velero https://github.com/looztra/asdf-velero

# asdf install goss 0.3.13
# asdf global goss 0.3.13

asdf install fd 8.2.1
asdf global fd 8.2.1

asdf install tmux 2.9a
asdf global tmux 2.9a

asdf install helm 3.6.3
asdf global helm 3.6.3

asdf install jsonnet 0.17.0
asdf global jsonnet 0.17.0

asdf install k9s 0.24.15
asdf global k9s 0.24.15

asdf install kubectl 1.22.1
asdf global kubectl 1.22.1

asdf install kubectx 0.9.4
asdf global kubectx 0.9.4

if [ "${OS}" = "Linux" ]; then
    asdf install kubeval 0.16.1
    asdf global kubeval 0.16.1
fi

asdf install neovim 0.6.0
asdf global neovim 0.6.0

asdf install packer 1.7.4
asdf global packer 1.7.4

asdf install terraform 1.0.6
asdf global terraform 1.0.6

asdf install vault 1.8.2
asdf global vault 1.8.2

asdf install poetry 1.1.8
asdf global poetry 1.1.8

asdf install yq 4.12.2
asdf global yq 4.12.2

# Install specific version
asdf install ag 2.2.0
asdf global ag 2.2.0

if [ "${OS}" = "Linux" ]; then
    asdf install aria2 1.36.0
    asdf global aria2 1.36.0
fi

asdf install dive 0.10.0
asdf global dive 0.10.0

asdf install kompose 1.24.0
asdf global kompose 1.24.0

asdf install github-cli 2.0.0
asdf global github-cli 2.0.0

asdf install mkcert latest
asdf global mkcert latest

asdf install shellcheck latest
asdf global shellcheck latest

asdf install shfmt 3.3.1
asdf global shfmt 3.3.1

asdf install velero v1.6.3
asdf global velero v1.6.3

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

echo " [ag] testing"
ag --help


set +e