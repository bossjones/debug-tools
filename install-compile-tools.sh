#!/usr/bin/env bash
sudo apt-get install systemtap-sdt-dev ktap -y

sudo apt-get install -y bison cmake ethtool flex git iperf libstdc++6 python-netaddr python-pip gcc gcc-c++ make zlib-dev elfutils-libelf-dev gnutls-dev python-dev
sudo apt-get install -y clang clang-dev llvm llvm-dev
sudo apt-get install -y luajit luajit-dev
pip install pyroute2

sudo apt-get -y install bison build-essential cmake flex git libedit-dev \
libllvm6.0 llvm-6.0-dev libclang-6.0-dev python zlib1g-dev libelf-dev

# how to install perf cmd
sudo apt install linux-tools-common -y
sudo apt-get install -y linux-headers-$(uname -r)
sudo apt install -y linux-cloud-tools-$(uname -r)

sudo apt-get install -y linux-tools-generic linux-cloud-tools-generic

SYSTEM=$(uname -s)
if [ "${SYSTEM}" = "Linux" ]; then
	sudo apt-get update -qq
	sudo apt-get -y install bison \
				autotools-dev \
				libncurses5-dev \
				libevent-dev \
				pkg-config \
				libutempter-dev \
				build-essential \
				automake
fi

if [ "${SYSTEM}" = "freebsd" ]; then
	sudo pkg install -y \
		automake \
		libevent \
		pkgconf
fi
