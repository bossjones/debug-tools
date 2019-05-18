#!/usr/bin/env bash

echo "This is the fix for the following error: "
echo 'Failed to get system container stats for "/system.slice/resolvconf-pull-resolved.service": failed to get cgroup stats for "/system.slice/resolvconf-pull-resolved.service": failed to get container info for "/system.slice/resolvconf-pull-resolved.service": unknown container "/system.slice/resolvconf-pull-resolved.service" '
echo "SOURCE: https://github.com/kubernetes/kubernetes/issues/56850"
echo -e "\n\n\n"


# /etc/systemd/system/resolvconf-pull-resolved.service.d/11-cgroups.conf
# /lib/systemd/system/resolvconf-pull-resolved.service

mkdir -p /etc/systemd/system/resolvconf-pull-resolved.service.d
cat <<EOF >/etc/systemd/system/resolvconf-pull-resolved.service.d/11-cgroups.conf
[Service]
StartLimitBurst=0
EOF

echo "-----------------------------------------------------"
echo "[run] cat /etc/systemd/system/resolvconf-pull-resolved.service.d/11-cgroups.conf"
echo "-----------------------------------------------------"
cat /etc/systemd/system/resolvconf-pull-resolved.service.d/11-cgroups.conf
echo "-----------------------------------------------------"
echo ""

echo "-----------------------------------------------------"
echo "[run] Now run the following"
echo "-----------------------------------------------------"
echo "systemctl daemon-reload"
echo -e "systemctl restart resolvconf-pull-resolved.service\n\n"
echo "-----------------------------------------------------"
