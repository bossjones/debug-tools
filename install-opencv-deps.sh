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

    sudo apt install libopus-dev libmp3lame-dev libfdk-aac-dev libvpx-dev libx264-dev yasm libass-dev libtheora-dev libvorbis-dev mercurial cmake build-essential -y

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
    sudo apt-get install linux-headers-$(uname -r) -y
    # https://github.com/opencv-deps/opencv-deps/wiki/Common-build-problems
    sudo add-apt-repository -y ppa:nilarimogard/webupd8
    sudo apt-get update
    sudo apt-get install youtube-dl -y
    sudo apt install imagemagick -y
    sudo apt install fdupes  libimage-exiftool-perl icu-devtools icu-doc libicu-dev -y
    sudo apt-get install -y libxslt-dev perl doxygen
    sudo apt-get install -y hdf5-tools
    sudo apt-get install -y libjpeg-dev
    sudo apt-get install -y libpng-dev
    sudo apt-get install -y libtiff-dev
    sudo apt-get install -y openexr libeigen3-dev libbtbb-dev libbtbb1  libmkl-tbb-thread libtbb-dev libtbb2
    sudo apt-get install python3-numpy libopenblas-dev -y
    sudo apt-get install -y libomp-dev
    sudo apt-get install -y openmpi-bin tcl-dev
    sudo apt install sqlite3 -y
    sudo apt-get install -y xz-utils
    sudo apt install zlib1g-dev -y
    sudo apt-get install -y libmagic-dev libffi-dev
    sudo apt-get install -y atomicparsley tree
    sudo add-apt-repository -y ppa:alex-p/tesseract-ocr5
    sudo apt-get update
    set -x
    sudo apt install -y tesseract-ocr nmap
    sudo apt-get install -y libavcodec-dev libavcodec-extra libghc-sdl2-dev libsdl2-dev  libsdl2-image-dev libsndifsdl2-dev libsdl2-ttf-dev python3-sdl2
    sudo apt-get install -y libsdl2-mixer-2.0-0
    sudo apt-get install -y libsdl2-mixer-dev
    sudo apt-get install -y python3-pydub

    sudo apt-get install -y squishyball \
    libsamplerate0-dev \
    libsamplerate0 \
    ladspa-sdk \
    python3-bitstring \
    python3-eyed3 \
    python3-guidata \
    python3-pdfrw \
    python3-releases \
    python3-netaddr
    # freqtweak \

    # SOURCE: https://trac.ffmpeg.org/wiki/CompilationGuide/Ubuntu
    sudo apt-get update -qq && sudo apt-get -y install \
    autoconf \
    automake \
    build-essential \
    cmake \
    git-core \
    libass-dev \
    libfreetype6-dev \
    libgnutls28-dev \
    libmp3lame-dev \
    libsdl2-dev \
    libtool \
    libva-dev \
    libvdpau-dev \
    libvorbis-dev \
    libxcb1-dev \
    libxcb-shm0-dev \
    libxcb-xfixes0-dev \
    meson \
    ninja-build \
    pkg-config \


    sudo apt install libunistring-dev libaom-dev -y
    sudo apt-get install build-essential cmake git unzip pkg-config libopenblas-dev  liblapack-dev -y
    sudo apt-get install python3-numpy python3-scipy python3-matplotlib -y
    sudo apt-get install libhdf5-serial-dev python3-h5py -y
    sudo apt-get install graphviz -y
    sudo apt-get install python3-opencv -y
    pip install pydot-ng

    sudo apt-get install -y aria2 \
    libaria2 \
    libaria2-0 \
    libaria2-0-dev

    sudo apt install libopencv-dev python3-opencv -y


    logmsg ">>> Installing prereqs cuda"
    # https://developer.nvidia.com/cuda-downloads?target_os=Linux&target_arch=x86_64&Distribution=Ubuntu&target_version=20.04&target_type=deb_local

    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/cuda-ubuntu2004.pin
    sudo mv cuda-ubuntu2004.pin /etc/apt/preferences.d/cuda-repository-pin-600
    wget https://developer.download.nvidia.com/compute/cuda/11.5.1/local_installers/cuda-repo-ubuntu2004-11-5-local_11.5.1-495.29.05-1_amd64.deb
    sudo dpkg -i cuda-repo-ubuntu2004-11-5-local_11.5.1-495.29.05-1_amd64.deb
    sudo apt-key add /var/cuda-repo-ubuntu2004-11-5-local/7fa2af80.pub
    sudo apt-get update
    sudo apt-get -y install cuda

    logmsg ">>> Install cuDNN"
    logmsg ">>> Download and rsync from https://developer.nvidia.com/rdp/cudnn-download"
    # https://www.nfaicompany.com/how-to-install-keras-and-its-dependencies-on-ubuntu-20-04/
    # sudo dpkg -i dpkg -i libcudnn6*.deb
    # sudo dpkg -i dpkg -i libcudnn6*.deb

    set +x
fi



exit 0
