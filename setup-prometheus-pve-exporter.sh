#!/bin/bash

# Script for setting up Prometheus monitoring on Proxmox
# Based on prometheus-pve-exporter
# This script creates the necessary Proxmox user, API token, and configuration

set -e

# Configuration variables
PVE_USER="prometheus-pve-exporter@pve"
PVE_TOKEN_ID="monitoring"
PVE_TOKEN_OUTPUT="/root/prometheus-pve-exporter-token.txt"
PVE_CONFIG_DIR="/etc/prometheus"
PVE_ENV_FILE="${PVE_CONFIG_DIR}/prometheus-pve-exporter.env"
SYSTEMD_UNIT_FILE="/etc/systemd/system/prometheus-pve-exporter.service"
VENV_PATH="/opt/prometheus-pve-exporter"

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y python3-venv

# Create prometheus-pve-exporter user
echo "Creating Proxmox user for monitoring..."
pveum user add ${PVE_USER} --password "TemporaryPassword123" --comment "API User for Prometheus monitoring"

# Set user permissions (PVEAuditor role for read-only access)
echo "Setting permissions for ${PVE_USER}..."
pveum acl modify / -user ${PVE_USER} -role PVEAuditor

# Create API token
echo "Creating API token for ${PVE_USER}..."
TOKEN_INFO=$(pveum user token add ${PVE_USER} ${PVE_TOKEN_ID} --comment "Token for Prometheus monitoring")

# Extract the token value
TOKEN_VALUE=$(echo "$TOKEN_INFO" | grep -oP "value: \K.*")

# Save token info to a file for future reference
echo "Saving token information to ${PVE_TOKEN_OUTPUT}..."
cat > ${PVE_TOKEN_OUTPUT} << EOF
# Proxmox API token for Prometheus monitoring
# Created on $(date)
# User: ${PVE_USER}
# Token ID: ${PVE_TOKEN_ID}
#
# Full API token format for HTTP Authorization header:
# PVEAPIToken=${PVE_USER}!${PVE_TOKEN_ID}=${TOKEN_VALUE}

PVE_USER="${PVE_USER}"
PVE_TOKEN_ID="${PVE_TOKEN_ID}"
PVE_TOKEN_VALUE="${TOKEN_VALUE}"
EOF

# Set secure permissions on token file
chmod 600 ${PVE_TOKEN_OUTPUT}

# Create config directory if it doesn't exist
mkdir -p ${PVE_CONFIG_DIR}

# Create environment file for prometheus-pve-exporter
echo "Creating environment file at ${PVE_ENV_FILE}..."
cat > ${PVE_ENV_FILE} << EOF
# Proxmox VE credentials using API token
PVE_USER="${PVE_USER}"
PVE_TOKEN_NAME="${PVE_TOKEN_ID}"
PVE_TOKEN_VALUE="${TOKEN_VALUE}"

# SSL verification (false for self-signed certificates)
PVE_VERIFY_SSL=false

# Configuration module name
PVE_MODULE=default

# Your Proxmox host URL (change this to your Proxmox host IP or hostname)
PVE_HOST=$(hostname -I | awk '{print $1}'):8006
EOF

# Set secure permissions on env file
chmod 600 ${PVE_ENV_FILE}

# Create Python virtual environment
echo "Creating Python virtual environment..."
python3 -m venv ${VENV_PATH}

# Install prometheus-pve-exporter in virtual environment
echo "Installing prometheus-pve-exporter in virtual environment..."
${VENV_PATH}/bin/pip install prometheus-pve-exporter

# Install the systemd unit file
echo "Installing systemd unit file..."
cat > ${SYSTEMD_UNIT_FILE} << 'EOF'
[Unit]
Description=Prometheus Proxmox VE Exporter
Documentation=https://github.com/bossjones/prometheus-pve-exporter
After=local-fs.target network-online.target network.target
Wants=local-fs.target network-online.target network.target

[Service]
Type=simple
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
EnvironmentFile=/etc/prometheus/prometheus-pve-exporter.env
KillMode=process
Delegate=yes
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
User=prometheus-pve-exporter
Group=prometheus-pve-exporter

ExecStart=/opt/prometheus-pve-exporter/bin/prometheus-pve-exporter \
    --collector.status \
    --collector.version \
    --collector.node \
    --collector.cluster \
    --collector.resources

ExecStartPre=-/usr/sbin/iptables -A INPUT -p tcp --dport 9221 -m state --state NEW -j ACCEPT

[Install]
WantedBy=multi-user.target
EOF

# Create prometheus-pve-exporter system user if it doesn't exist
if ! id -u prometheus-pve-exporter > /dev/null 2>&1; then
  echo "Creating prometheus-pve-exporter system user..."
  useradd --system --no-create-home --shell /bin/false prometheus-pve-exporter
fi

# Ensure prometheus-pve-exporter user has access to the config files and virtual environment
chown -R prometheus-pve-exporter:prometheus-pve-exporter ${PVE_CONFIG_DIR}
chown -R prometheus-pve-exporter:prometheus-pve-exporter ${VENV_PATH}

# Enable and start the service
echo "Enabling and starting prometheus-pve-exporter service..."
systemctl daemon-reload
systemctl enable prometheus-pve-exporter
systemctl restart prometheus-pve-exporter
systemctl status prometheus-pve-exporter

echo ""
echo "Setup complete!"
echo "Token information saved to: ${PVE_TOKEN_OUTPUT}"
echo "Environment file created at: ${PVE_ENV_FILE}"
echo "Systemd unit file installed at: ${SYSTEMD_UNIT_FILE}"
echo "Virtual environment created at: ${VENV_PATH}"
echo ""
echo "You can monitor Prometheus PVE Exporter setup with: systemctl status prometheus-pve-exporter"
echo "View metrics at: http://$(hostname -I | awk '{print $1}'):9221/metrics"
