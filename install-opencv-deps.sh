#!/usr/bin/env bash

set -e

#-----------------------------------------------------------------------
# Linux (Linux/x86_64, Darwin/x86_64, Linux/armv7l)
#
# install-opencv-deps.sh - Install opencv-deps
#
# usage: install-opencv-deps.sh
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


#
# Install opencv-deps
#
OS=$(uname -s)
ARCH=$(uname -m)
UNAME_A=$(uname -a)



case ${OS} in
  Linux)  OS=linux;;
  Darwin) OS=darwin;;
  *) echo "${OS}-${ARCH} does'nt supported yet."; exit 1;;
esac

case ${ARCH} in
  x86_64) ARCH=amd64;;
  armv7l) ARCH=armv6l;;
  *) echo "${OS}-${ARCH} does'nt supported yet."; exit 1;;
esac


if [[ "$(echo ${UNAME_A} | grep -i 'ubuntu' | wc -l)" = "1" ]]; then
    logmsg ">>> Installing prereqs opencv-deps"
    # https://github.com/opencv-deps/opencv-deps/wiki/Common-build-problems
    sudo apt-get update && \
    sudo apt install -y build-essential cmake git pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev libopenexr-dev \
    libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev
fi

if [[ "$(echo ${UNAME_A} | grep -i 'ubuntu' | wc -l)" = "1" ]]; then
    logmsg ">>> Installing prereqs ffmpeg"
    sudo apt install \
    autoconf \
    automake \
    build-essential \
    cmake \
    git-core \
    libass-dev \
    libfreetype6-dev \
    libgnutls28-dev \
    libsdl2-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    pkg-config \
    texinfo \
    wget \
    yasm \
    zlib1g-dev -y

    sudo apt install nasm  -y
    sudo apt install  libx264-dev  -y
    sudo apt install  libx265-dev libnuma-dev  -y
    sudo apt install  libvpx-dev  -y
    sudo apt install  libfdk-aac-dev  -y
    sudo apt install libmp3lame-dev -y
    sudo apt install libopus-dev -y
    sudo apt install  libaom-dev -y
    sudo apt install -y libunistring-dev

    # https://github.com/opencv-deps/opencv-deps/wiki/Common-build-problems
    sudo add-apt-repository -y ppa:nilarimogard/webupd8
    sudo apt-get update
    sudo apt-get install youtube-dl -y

fi

if [[ "$(echo ${UNAME_A} | grep -i 'ubuntu' | wc -l)" = "1" ]]; then
    logmsg ">>> Installing prereqs youtube-dl"
    # https://github.com/opencv-deps/opencv-deps/wiki/Common-build-problems
    sudo add-apt-repository -y ppa:nilarimogard/webupd8
    sudo apt-get update
    sudo apt-get install youtube-dl -y

fi


exit 0