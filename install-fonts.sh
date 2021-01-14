#!/usr/bin/env bash

SYSTEM=$(uname -s)
if [ "${SYSTEM}" = "Linux" ]; then
	mkdir -p ~/.local/share/fonts || true
	cd ~/dev
	# clone
	git clone https://github.com/powerline/fonts.git --depth=1
	# install
	cd fonts
	./install.sh
	# clean-up a bit
	cd ..
	rm -rf fonts
elif [ "${SYSTEM}" = "Darwin" ]; then
	mkdir -p ~/dev/powerline || true
	cd ~/dev
	# clone
	git clone https://github.com/powerline/fonts.git --depth=1 || true
	# install
	cd fonts
	bash -x ./install.sh
	# clean-up a bit
	cd ..
	rm -rf fonts
fi
