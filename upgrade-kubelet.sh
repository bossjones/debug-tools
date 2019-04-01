#!/usr/bin/env bash

# SOURCE: https://github.com/ProBattu/kubernetes-website/blob/7c987a81b85470c678458fff21b621582441570c/content/en/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade-ha-1-12.md

NEW_K8S_VERSION=${$1:-1.13.4-00}

source /usr/local/bin/color-echo-helper

# use your distro's package manager, e.g. 'apt-get' on Debian-based systems
# for the versions stick to kubeadm's output (see above)
cecho " [run] unholding packages ( kubelet kubectl ) " $GREEN
apt-mark unhold kubelet kubectl && \
apt-get update

cecho " [run] installing packages ( kubelet kubectl ) version ${NEW_K8S_VERSION}" $GREEN
apt-get install kubelet=${NEW_K8S_VERSION} kubectl=${NEW_K8S_VERSION}

cecho " [run] holding packages ( kubelet kubectl ) " $GREEN
apt-mark hold kubelet kubectl

cecho " [run] restart kubelet" $GREEN
systemctl restart kubelet
