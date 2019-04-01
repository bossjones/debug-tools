#!/usr/bin/env bash

source /usr/local/bin/color-echo-helper

cd ~/

cecho " [run] kubectl get configmaps -n kube-system kubeadm-config -o yaml > ~/kubeadm-config-cm.yaml " $GREEN

kubectl get configmaps -n kube-system kubeadm-config -o yaml > ~/kubeadm-config-cm.yaml

echo ""
echo ""

cat ~/kubeadm-config-cm.yaml

echo ""
echo ""
