#!/usr/bin/env bash

# https://github.com/nikhita/machine-controller/blob/90bbf926d7bbfa4c5cb33327819c257899f5a6ac/pkg/userdata/centos/testdata/kubelet-v1.12-vsphere.golden

sysctl -w fs.inotify.max_user_watches=1048576
