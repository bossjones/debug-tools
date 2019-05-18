#!/usr/bin/env bash

echo "This is the fix for the allowing MEMLOCK inside of docker: "

echo -e "\n\n\n"

mkdir -p /etc/systemd/system/docker.service.d
cat <<EOF >/etc/systemd/system/docker.service.d/11-memlock.conf
[Service]
# this allows mlockall:true
LimitMEMLOCK=infinity
EOF

echo "-----------------------------------------------------"
echo "[run] cat /etc/systemd/system/docker.service.d/11-memlock.conf"
echo "-----------------------------------------------------"
cat /etc/systemd/system/docker.service.d/11-memlock.conf
echo "-----------------------------------------------------"
echo ""

echo "-----------------------------------------------------"
echo "[run] Now run the following"
echo "-----------------------------------------------------"
echo "systemctl daemon-reload"
echo -e "systemctl restart docker\n\n"
echo "-----------------------------------------------------"
