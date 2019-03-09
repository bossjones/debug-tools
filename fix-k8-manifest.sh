#!/bin/bash

# sudo sed -i 's/failureThreshold: 8/failureThreshold: 20/g' /etc/kubernetes/manifests/kube-apiserver.yaml && \
# sed -i 's/initialDelaySeconds: [0-9]\+/initialDelaySeconds: 360/' /etc/kubernetes/manifests/kube-apiserver.yaml

source /usr/local/bin/color-echo-helper

cecho " [cmd] perf sched record -- sleep 15" $BLUE
sed -e "s/- --address=127.0.0.1/- --address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-controller-manager.yaml
cat  /etc/kubernetes/manifests/kube-controller-manager.yaml
echo

cecho " [run] sed command to change address from 127.0.0.1 to 0.0.0.0 in kube-controller-scheduler " $GREEN
sed -e "s/- --address=127.0.0.1/- --address=0.0.0.0/" -i /etc/kubernetes/manifests/kube-scheduler.yaml
cat /etc/kubernetes/manifests/kube-scheduler.yaml
