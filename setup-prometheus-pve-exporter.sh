#!/bin/bash

# Script for setting up Prometheus monitoring on Proxmox
# Based on prometheus-pve-exporter
# This script creates the necessary Proxmox user, API token, and configuration
# This script is idempotent - it can be run multiple times to update configurations

set -e

# Configuration variables
PVE_USER="prometheus-pve-exporter@pve"
PVE_TOKEN_ID="monitoring"
PVE_TOKEN_OUTPUT="/root/prometheus-pve-exporter-token.txt"
PVE_CONFIG_DIR="/etc/prometheus"
PVE_ENV_FILE="${PVE_CONFIG_DIR}/prometheus-pve-exporter.env"
PVE_CONFIG_FILE="${PVE_CONFIG_DIR}/config.yaml"
SYSTEMD_UNIT_FILE="/etc/systemd/system/prometheus-pve-exporter.service"
VENV_PATH="/opt/prometheus-pve-exporter"

# Helper function to check if a command succeeds silently
command_exists() {
  "$@" &> /dev/null
  return $?
}

# Install required packages
echo "Installing required packages..."
apt-get update
apt-get install -y python3-venv

# Check if Proxmox user exists, create if it doesn't
if ! command_exists pveum user list | grep -q "${PVE_USER}"; then
  echo "Creating Proxmox user for monitoring..."
  pveum user add ${PVE_USER} --password "TemporaryPassword123" --comment "API User for Prometheus monitoring"

  # Set user permissions (PVEAuditor role for read-only access)
  echo "Setting permissions for ${PVE_USER}..."
  pveum acl modify / -user ${PVE_USER} -role PVEAuditor
else
  echo "Proxmox user ${PVE_USER} already exists, skipping creation."
fi

# Check if token exists, create if it doesn't
TOKEN_EXISTS=$(pveum user token list ${PVE_USER} 2>/dev/null | grep -c "${PVE_TOKEN_ID}" || echo "0")

if [ "$TOKEN_EXISTS" -eq "0" ]; then
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
else
  echo "API token ${PVE_TOKEN_ID} for ${PVE_USER} already exists."
  echo "Note: Token values can only be retrieved at creation time."
  echo "If you need a new token, please delete the existing one first:"
  echo "  pveum user token remove ${PVE_USER} ${PVE_TOKEN_ID}"

  if [ -f "${PVE_TOKEN_OUTPUT}" ]; then
    echo "Using token information from ${PVE_TOKEN_OUTPUT}..."
    source ${PVE_TOKEN_OUTPUT}
    TOKEN_VALUE="${PVE_TOKEN_VALUE}"
  else
    echo "ERROR: Cannot find token value. Token file ${PVE_TOKEN_OUTPUT} does not exist."
    echo "Please delete the existing token and run this script again, or manually create"
    echo "the token and update ${PVE_TOKEN_OUTPUT} with the token value."
    exit 1
  fi
fi

# Create config directory if it doesn't exist
mkdir -p ${PVE_CONFIG_DIR}

# Create config.yaml file for the exporter
echo "Creating/updating config file at ${PVE_CONFIG_FILE}..."
cat > ${PVE_CONFIG_FILE} << EOF
default:
  user: ${PVE_USER}
  token_name: ${PVE_TOKEN_ID}
  token_value: ${TOKEN_VALUE}
  verify_ssl: false
EOF

# Set secure permissions on config file
chmod 600 ${PVE_CONFIG_FILE}

# Create environment file for prometheus-pve-exporter
echo "Creating/updating environment file at ${PVE_ENV_FILE}..."
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

# Check if virtual environment exists
if [ ! -d "${VENV_PATH}" ]; then
  echo "Creating Python virtual environment..."
  python3 -m venv ${VENV_PATH}
  INSTALL_EXPORTER=true
else
  echo "Python virtual environment already exists at ${VENV_PATH}."
  read -p "Do you want to update the prometheus-pve-exporter? (y/n): " UPDATE_EXPORTER
  if [[ "${UPDATE_EXPORTER}" =~ ^[Yy]$ ]]; then
    INSTALL_EXPORTER=true
  else
    INSTALL_EXPORTER=false
  fi
fi

# Install or update prometheus-pve-exporter in virtual environment
if [ "${INSTALL_EXPORTER}" = true ]; then
  echo "Installing/updating prometheus-pve-exporter in virtual environment..."
  ${VENV_PATH}/bin/pip install --upgrade prometheus-pve-exporter
fi

# Install the systemd unit file
echo "Creating/updating systemd unit file..."
cat > ${SYSTEMD_UNIT_FILE} << EOF
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

# The binary name is pve_exporter
ExecStart=${VENV_PATH}/bin/pve_exporter ${PVE_CONFIG_FILE} \
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
else
  echo "System user prometheus-pve-exporter already exists."
fi

# Ensure prometheus-pve-exporter user has access to the config files and virtual environment
echo "Setting correct permissions on files and directories..."
chown -R prometheus-pve-exporter:prometheus-pve-exporter ${PVE_CONFIG_DIR}
chown -R prometheus-pve-exporter:prometheus-pve-exporter ${VENV_PATH}

# Enable and restart the service
echo "Reloading systemd configuration and restarting service..."
systemctl daemon-reload
systemctl enable prometheus-pve-exporter
systemctl restart prometheus-pve-exporter
systemctl status prometheus-pve-exporter || true

echo ""
echo "Setup complete!"
echo "Token information saved to: ${PVE_TOKEN_OUTPUT} (if newly created)"
echo "Config file: ${PVE_CONFIG_FILE}"
echo "Environment file: ${PVE_ENV_FILE}"
echo "Systemd unit file: ${SYSTEMD_UNIT_FILE}"
echo "Virtual environment: ${VENV_PATH}"
echo ""
echo "You can monitor Prometheus PVE Exporter with: systemctl status prometheus-pve-exporter"
echo "View metrics at: http://$(hostname -I | awk '{print $1}'):9221/metrics"
