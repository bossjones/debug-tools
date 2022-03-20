# source this file on ubuntu
set -x
. "$HOME"/.asdf/asdf.sh
asdf current
. /usr/local/bin/install-config
eval "$(rbenv init -)"
. $PYENV_ROOT/pyenv.bash
export PATH=/home/pi/.fnm:$PATH
eval "`fnm env`"
# set +e
. ~/goenv.bash
. $PYENV_ROOT/pyenv.bash
python3 -c "import sys;print(sys.executable)"
. ~/.fzf.bash
set +x
