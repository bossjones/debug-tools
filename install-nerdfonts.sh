#!/bin/bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-nerdfonts.sh - Install nerdfonts
#
# usage: install-nerdfonts.sh NON_ROOT_USER (use a non root user on your file system)
#
# Copyright (c) 2020 Malcolm Jones
# All Rights Reserved.
#-----------------------------------------------------------------------


logmsg() {
  echo ">>> $1"
}


_user=$1

if [[ "${_user}x" = "x" ]]; then
  NON_ROOT_USER=nobody
else
  NON_ROOT_USER=${_user}
fi

declare -a fonts=(
    BitstreamVeraSansMono
    CodeNewRoman
    DroidSansMono
    FiraCode
    FiraMono
    Go-Mono
    Hack
    Hermit
    JetBrainsMono
    Meslo
    Noto
    Overpass
    ProggyClean
    RobotoMono
    SourceCodePro
    SpaceMono
    Ubuntu
    UbuntuMono
)

version='2.1.0'
fonts_dir="~${NON_ROOT_USER}/.local/share/fonts"
expanded_dir=$(python -c "import os;print(os.path.expanduser('${fonts_dir}'));")
logmsg ">>> expanded_dir: ${expanded_dir}"

if [[ ! -d "$expanded_dir" ]]; then
    mkdir -p "$expanded_dir" || true
fi

for font in "${fonts[@]}"; do
    zip_file="${font}.zip"
    download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${version}/${zip_file}"
    echo "Downloading $download_url"
    wget "$download_url"
    unzip "$zip_file" -d "$expanded_dir"
    rm -v "$zip_file"
done

find "$expanded_dir" -name '*Windows Compatible*' -delete

logmsg ">>> refreshing font cache"
fc-cache -fv

exit 0
