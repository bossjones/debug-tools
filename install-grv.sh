#!/bin/bash

set -e

cd /usr/local/bin
wget -O grv https://github.com/rgburke/grv/releases/download/v0.3.1/grv_v0.3.1_linux64
chmod +x ./grv
cd -

exit 0
