#!/usr/bin/env bash

echo "This is the fix for the following error: "
echo 'Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service" '
echo "SOURCE: https://github.com/kubernetes/kubernetes/issues/56850"
echo -e "\n\n\n"


# /etc/systemd/system/kubelet.service.d/11-cgroups.conf


mkdir -p /etc/systemd/system/kubelet.service.d
cat <<EOF >/etc/systemd/system/kubelet.service.d/11-cgroups.conf
[Service]
CPUAccounting=true
MemoryAccounting=true

EOF

echo "-----------------------------------------------------"
echo "[run] cat /etc/systemd/system/kubelet.service.d/11-cgroups.conf"
echo "-----------------------------------------------------"
cat /etc/systemd/system/kubelet.service.d/11-cgroups.conf
echo "-----------------------------------------------------"
echo ""

echo "-----------------------------------------------------"
echo "[run] Now run the following"
echo "-----------------------------------------------------"
echo "systemctl daemon-reload"
echo -e "systemctl restart kubelet\n\n"
echo "-----------------------------------------------------"
