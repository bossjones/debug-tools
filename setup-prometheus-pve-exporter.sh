#!/bin/bash

# Script for setting up Prometheus monitoring on Proxmox
# Based on prometheus-pve-exporter
# This script creates the necessary Proxmox user, API token, and configuration
# This script is idempotent - it can be run multiple times to update configurations

set -e

# Terminal colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Configuration variables
PVE_USER="prometheus-pve-exporter@pve"
PVE_TOKEN_ID="monitoring"
PVE_TOKEN_OUTPUT="/root/prometheus-pve-exporter-token.txt"
PVE_CONFIG_DIR="/etc/prometheus"
PVE_ENV_FILE="${PVE_CONFIG_DIR}/prometheus-pve-exporter.env"
PVE_CONFIG_FILE="${PVE_CONFIG_DIR}/config.yaml"
SYSTEMD_UNIT_FILE="/etc/systemd/system/prometheus-pve-exporter.service"
VENV_PATH="/opt/prometheus-pve-exporter"
PVE_USER_PASSWORD="password"

# Install required packages
echo -e "${BLUE}Installing required packages...${NC}"
apt-get update
apt-get install -y python3-venv

# Check if Proxmox user exists, create if it doesn't
if pveum user list | grep -q "${PVE_USER}"; then
  echo -e "${GREEN}Proxmox user ${CYAN}${PVE_USER}${GREEN} already exists, skipping creation.${NC}"
else
  echo -e "${YELLOW}Creating Proxmox user for monitoring...${NC}"
  pveum user add ${PVE_USER} --password "${PVE_USER_PASSWORD}" --comment "API User for Prometheus monitoring"

  # Set user permissions (PVEAuditor role for read-only access)
  echo -e "${YELLOW}Setting permissions for ${CYAN}${PVE_USER}${NC}..."
  pveum acl modify / -user ${PVE_USER} -role PVEAuditor
fi

# Check if token exists using a more reliable method
TOKEN_EXISTS=0
if pveum user token list ${PVE_USER} 2>/dev/null | grep -q "${PVE_TOKEN_ID}"; then
  TOKEN_EXISTS=1
fi

if [ $TOKEN_EXISTS -eq 0 ]; then
  echo -e "${YELLOW}Creating API token for ${CYAN}${PVE_USER}${NC}..."
  TOKEN_INFO=$(pveum user token add ${PVE_USER} ${PVE_TOKEN_ID} --comment "Token for Prometheus monitoring")

  # Extract the token value
  TOKEN_VALUE=$(echo "$TOKEN_INFO" | grep -oP "value: \K.*")

  # Save token info to a file for future reference
  echo -e "${YELLOW}Saving token information to ${CYAN}${PVE_TOKEN_OUTPUT}${NC}..."
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
  echo -e "${GREEN}API token ${CYAN}${PVE_TOKEN_ID}${GREEN} for ${CYAN}${PVE_USER}${GREEN} already exists.${NC}"

  if [ -f "${PVE_TOKEN_OUTPUT}" ]; then
    echo -e "${YELLOW}Using token information from ${CYAN}${PVE_TOKEN_OUTPUT}${NC}..."
    # Source the file to get the token value
    source ${PVE_TOKEN_OUTPUT}
    TOKEN_VALUE="${PVE_TOKEN_VALUE}"
  else
    echo -e "${RED}Warning: Token exists but ${CYAN}${PVE_TOKEN_OUTPUT}${RED} does not exist.${NC}"
    echo -e "${YELLOW}Removing existing token and creating a new one...${NC}"
    pveum user token remove ${PVE_USER} ${PVE_TOKEN_ID}

    # Create a new token
    echo -e "${YELLOW}Creating new API token for ${CYAN}${PVE_USER}${NC}..."
    TOKEN_INFO=$(pveum user token add ${PVE_USER} ${PVE_TOKEN_ID} --comment "Token for Prometheus monitoring")

    # Extract the token value
    TOKEN_VALUE=$(echo "$TOKEN_INFO" | grep -oP "value: \K.*")

    # Save token info to a file for future reference
    echo -e "${YELLOW}Saving token information to ${CYAN}${PVE_TOKEN_OUTPUT}${NC}..."
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
  fi
fi

# Create config directory if it doesn't exist
mkdir -p ${PVE_CONFIG_DIR}

# Create config.yaml file for the exporter
echo -e "${YELLOW}Creating/updating config file at ${CYAN}${PVE_CONFIG_FILE}${NC}..."
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
echo -e "${YELLOW}Creating/updating environment file at ${CYAN}${PVE_ENV_FILE}${NC}..."
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
  echo -e "${YELLOW}Creating Python virtual environment...${NC}"
  python3 -m venv ${VENV_PATH}
  echo -e "${YELLOW}Installing prometheus-pve-exporter in virtual environment...${NC}"
  ${VENV_PATH}/bin/pip install prometheus-pve-exporter
else
  echo -e "${GREEN}Python virtual environment already exists at ${CYAN}${VENV_PATH}${GREEN}.${NC}"
  echo -e "${YELLOW}Updating prometheus-pve-exporter in virtual environment...${NC}"
  ${VENV_PATH}/bin/pip install --upgrade prometheus-pve-exporter
fi

# Install the systemd unit file
echo -e "${YELLOW}Creating/updating systemd unit file...${NC}"
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
ExecStart=${VENV_PATH}/bin/pve_exporter --config.file=${PVE_CONFIG_FILE} \
    --collector.status \
    --collector.version \
    --collector.node \
    --collector.cluster \
    --collector.resources

# ExecStartPre=-/usr/sbin/iptables -A INPUT -p tcp --dport 9221 -m state --state NEW -j ACCEPT

[Install]
WantedBy=multi-user.target
EOF

# Create prometheus-pve-exporter system user if it doesn't exist
if ! id -u prometheus-pve-exporter > /dev/null 2>&1; then
  echo -e "${YELLOW}Creating prometheus-pve-exporter system user...${NC}"
  useradd --system --no-create-home --shell /bin/false prometheus-pve-exporter
else
  echo -e "${GREEN}System user prometheus-pve-exporter already exists.${NC}"
fi

# Ensure prometheus-pve-exporter user has access to the config files and virtual environment
echo -e "${YELLOW}Setting correct permissions on files and directories...${NC}"
chown -R prometheus-pve-exporter:prometheus-pve-exporter ${PVE_CONFIG_DIR}
chown -R prometheus-pve-exporter:prometheus-pve-exporter ${VENV_PATH}

# Enable and restart the service
echo -e "${YELLOW}Reloading systemd configuration and restarting service...${NC}"
systemctl daemon-reload
systemctl enable prometheus-pve-exporter
systemctl restart prometheus-pve-exporter
systemctl status prometheus-pve-exporter || true

# Function to print summary
print_summary() {
  local IP_ADDRESS=$(hostname -I | awk '{print $1}')

  echo ""
  echo -e "${BOLD}${GREEN}======== SETUP SUMMARY ========${NC}"
  echo ""

  # Files section
  echo -e "${BOLD}${BLUE}Files:${NC}"

  # Token file
  if [ -f "${PVE_TOKEN_OUTPUT}" ]; then
    local TOKEN_PERMS=$(stat -c "%a" ${PVE_TOKEN_OUTPUT})
    local TOKEN_OWNER=$(stat -c "%U:%G" ${PVE_TOKEN_OUTPUT})
    echo -e "  ${GREEN}✓${NC} Token file: ${YELLOW}${PVE_TOKEN_OUTPUT}${NC} (permissions: ${TOKEN_PERMS}, owner: ${TOKEN_OWNER})"
  else
    echo -e "  ${RED}✗${NC} Token file: ${YELLOW}${PVE_TOKEN_OUTPUT}${NC} (not created)"
  fi

  # Config file
  if [ -f "${PVE_CONFIG_FILE}" ]; then
    local CONFIG_PERMS=$(stat -c "%a" ${PVE_CONFIG_FILE})
    local CONFIG_OWNER=$(stat -c "%U:%G" ${PVE_CONFIG_FILE})
    echo -e "  ${GREEN}✓${NC} Config file: ${YELLOW}${PVE_CONFIG_FILE}${NC} (permissions: ${CONFIG_PERMS}, owner: ${CONFIG_OWNER})"
  else
    echo -e "  ${RED}✗${NC} Config file: ${YELLOW}${PVE_CONFIG_FILE}${NC} (not created)"
  fi

  # Environment file
  if [ -f "${PVE_ENV_FILE}" ]; then
    local ENV_PERMS=$(stat -c "%a" ${PVE_ENV_FILE})
    local ENV_OWNER=$(stat -c "%U:%G" ${PVE_ENV_FILE})
    echo -e "  ${GREEN}✓${NC} Environment file: ${YELLOW}${PVE_ENV_FILE}${NC} (permissions: ${ENV_PERMS}, owner: ${ENV_OWNER})"
  else
    echo -e "  ${RED}✗${NC} Environment file: ${YELLOW}${PVE_ENV_FILE}${NC} (not created)"
  fi

  # Systemd unit file
  if [ -f "${SYSTEMD_UNIT_FILE}" ]; then
    local UNIT_PERMS=$(stat -c "%a" ${SYSTEMD_UNIT_FILE})
    local UNIT_OWNER=$(stat -c "%U:%G" ${SYSTEMD_UNIT_FILE})
    echo -e "  ${GREEN}✓${NC} Systemd unit file: ${YELLOW}${SYSTEMD_UNIT_FILE}${NC} (permissions: ${UNIT_PERMS}, owner: ${UNIT_OWNER})"
  else
    echo -e "  ${RED}✗${NC} Systemd unit file: ${YELLOW}${SYSTEMD_UNIT_FILE}${NC} (not created)"
  fi

  # Virtual environment
  if [ -d "${VENV_PATH}" ]; then
    local VENV_PERMS=$(stat -c "%a" ${VENV_PATH})
    local VENV_OWNER=$(stat -c "%U:%G" ${VENV_PATH})
    echo -e "  ${GREEN}✓${NC} Virtual environment: ${YELLOW}${VENV_PATH}${NC} (permissions: ${VENV_PERMS}, owner: ${VENV_OWNER})"
  else
    echo -e "  ${RED}✗${NC} Virtual environment: ${YELLOW}${VENV_PATH}${NC} (not created)"
  fi

  echo ""

  # Systemd service section
  echo -e "${BOLD}${BLUE}Service Status:${NC}"

  # Check if service is enabled
  if systemctl is-enabled prometheus-pve-exporter &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Service is enabled at boot"
  else
    echo -e "  ${RED}✗${NC} Service is NOT enabled at boot"
  fi

  # Check if service is active
  if systemctl is-active prometheus-pve-exporter &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Service is currently running"

    # Get more detailed service info
    local SERVICE_PID=$(systemctl show -p MainPID --value prometheus-pve-exporter)
    local SERVICE_MEM=$(ps -o rss= -p ${SERVICE_PID} 2>/dev/null | awk '{print int($1/1024)" MB"}' 2>/dev/null || echo "unknown")
    local SERVICE_TIME=$(systemctl show -p ActiveEnterTimestamp --value prometheus-pve-exporter | awk '{print $1, $2}')

    echo -e "  ${GREEN}•${NC} PID: ${SERVICE_PID}, Memory: ${SERVICE_MEM}, Active since: ${SERVICE_TIME}"
  else
    echo -e "  ${RED}✗${NC} Service is NOT running"
  fi

  # Get listening port
  if command -v ss >/dev/null && ss -tlnp | grep -q "pve_exporter"; then
    local PORT_INFO=$(ss -tlnp | grep "pve_exporter" | awk '{print $4}' | cut -d':' -f2)
    echo -e "  ${GREEN}•${NC} Listening on port: ${PORT_INFO}"
  fi

  echo ""

  # Proxmox user section
  echo -e "${BOLD}${BLUE}Proxmox Configuration:${NC}"

  # Check if user exists
  if pveum user list | grep -q "${PVE_USER}"; then
    echo -e "  ${GREEN}✓${NC} Proxmox user ${CYAN}${PVE_USER}${NC} exists"

    # Check if token exists
    if pveum user token list ${PVE_USER} 2>/dev/null | grep -q "${PVE_TOKEN_ID}"; then
      echo -e "  ${GREEN}✓${NC} API token ${CYAN}${PVE_TOKEN_ID}${NC} exists for user ${CYAN}${PVE_USER}${NC}"
    else
      echo -e "  ${RED}✗${NC} API token ${CYAN}${PVE_TOKEN_ID}${NC} does NOT exist for user ${CYAN}${PVE_USER}${NC}"
    fi

    # Check user permissions
    local USER_PERMS=$(pveum acl list | grep ${PVE_USER} | awk '{print $2, $4}')
    if [ -n "${USER_PERMS}" ]; then
      echo -e "  ${GREEN}•${NC} User permissions: ${USER_PERMS}"
    fi
  else
    echo -e "  ${RED}✗${NC} Proxmox user ${CYAN}${PVE_USER}${NC} does NOT exist"
  fi

  echo ""

  # Network information section
  echo -e "${BOLD}${BLUE}Network Information:${NC}"
  echo -e "  ${GREEN}•${NC} Proxmox Server: ${MAGENTA}https://${IP_ADDRESS}:8006${NC}"
  echo -e "  ${GREEN}•${NC} Exporter metrics: ${MAGENTA}http://${IP_ADDRESS}:9221/metrics${NC}"

  # Perform a quick check if metrics endpoint is accessible
  if command -v curl >/dev/null; then
    if curl -s --connect-timeout 2 http://${IP_ADDRESS}:9221/metrics >/dev/null; then
      echo -e "  ${GREEN}✓${NC} Metrics endpoint is accessible"
    else
      echo -e "  ${RED}✗${NC} Metrics endpoint is NOT accessible"
    fi
  fi

  echo ""

  # Next steps
  echo -e "${BOLD}${BLUE}Next Steps:${NC}"
  echo -e "  ${YELLOW}•${NC} Monitor service: ${MAGENTA}systemctl status prometheus-pve-exporter${NC}"
  echo -e "  ${YELLOW}•${NC} View logs: ${MAGENTA}journalctl -u prometheus-pve-exporter${NC}"
  echo -e "  ${YELLOW}•${NC} Test metrics: ${MAGENTA}curl http://${IP_ADDRESS}:9221/metrics${NC}"
  echo -e "  ${YELLOW}•${NC} Configure Prometheus server to scrape: ${MAGENTA}${IP_ADDRESS}:9221/metrics${NC}"

  echo ""
  echo -e "${BOLD}${GREEN}======== SETUP COMPLETE ========${NC}"
  echo ""
}

# Call the summary function
print_summary
