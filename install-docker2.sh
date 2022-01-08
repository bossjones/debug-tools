#!/bin/bash

sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
# # run docker commands as vagrant user (sudo not required)
sudo usermod -aG docker `whoami`
# apt-get install -y apt-transport-https curl



exit 0
