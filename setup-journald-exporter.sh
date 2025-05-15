#!/bin/bash

# Script for setting up journald-exporter
# This script creates the necessary user, directories, and systemd service
# This script is idempotent - it can be run multiple times to update configurations

set -euo pipefail

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
JOURNALD_CONFIG_DIR="/etc/journald-exporter"
JOURNALD_KEYS_DIR="${JOURNALD_CONFIG_DIR}/keys"
PROMETHEUS_KEYS_DIR="/etc/prometheus-keys"
SYSTEMD_UNIT_FILE="/etc/systemd/system/journald-exporter.service"
BINARY_PATH="/usr/local/bin/journald-exporter"
KEY_NAME="$(date -u +'%Y-%m-%dT%H:%M:%SZ.key')"
PORT=12345

# Check if systemd-journald is running
check_systemd_journald() {
    echo -e "${BLUE}Checking if systemd-journald is running...${NC}"
    if [[ ! -e /run/systemd/journal/socket ]]; then
        echo -e "${RED}Error: systemd-journald is not running. Please ensure both systemd and systemd-journald are running.${NC}"
        exit 1
    fi
}

# Download the latest journald-exporter binary
download_binary() {
    echo -e "${BLUE}Downloading journald-exporter binary...${NC}"
    local remote_url="https://github.com/dead-claudia/journald-exporter/releases/latest/download/journald-exporter"

    if command -v curl >/dev/null 2>&1; then
        curl \
            --output "${BINARY_PATH}.tmp" \
            --fail \
            --silent \
            --show-error \
            --connect-timeout 5 \
            --retry 5 \
            --retry-all-errors \
            --retry-max-time 15 \
            --max-time 60 \
            --location \
            "${remote_url}"
    elif command -v wget >/dev/null 2>&1; then
        wget \
            --tries=5 \
            --timeout=5 \
            --waitretry=5 \
            --retry-connrefused \
            --output-document="${BINARY_PATH}.tmp" \
            "${remote_url}"
    else
        echo -e "${RED}Error: Neither curl nor wget detected. Please install one of them.${NC}"
        exit 1
    fi

    chmod 755 "${BINARY_PATH}.tmp"
    mv "${BINARY_PATH}.tmp" "${BINARY_PATH}"
}

# Create necessary directories and files
setup_directories() {
    echo -e "${BLUE}Setting up directories...${NC}"

    # Create main config directory
    mkdir -p "${JOURNALD_CONFIG_DIR}"
    chmod 755 "${JOURNALD_CONFIG_DIR}"

    # Create keys directory
    mkdir -p "${JOURNALD_KEYS_DIR}"
    chmod 755 "${JOURNALD_KEYS_DIR}"

    # Create Prometheus keys directory
    mkdir -p "${PROMETHEUS_KEYS_DIR}"
    chmod 755 "${PROMETHEUS_KEYS_DIR}"
}

# Generate API key
generate_api_key() {
    echo -e "${BLUE}Generating API key...${NC}"

    # Generate new API key
    openssl rand -hex 32 > "${JOURNALD_KEYS_DIR}/${KEY_NAME}"
    chmod 600 "${JOURNALD_KEYS_DIR}/${KEY_NAME}"

    # Copy key for Prometheus
    cp "${JOURNALD_KEYS_DIR}/${KEY_NAME}" "${PROMETHEUS_KEYS_DIR}/journald-exporter.key"
    chmod 640 "${PROMETHEUS_KEYS_DIR}/journald-exporter.key"

    if getent group prometheus >/dev/null; then
        chgrp prometheus "${PROMETHEUS_KEYS_DIR}/journald-exporter.key"
    fi
}

# Create systemd service
create_systemd_service() {
    echo -e "${BLUE}Creating systemd service...${NC}"

    cat > "${SYSTEMD_UNIT_FILE}" << EOF
[Unit]
Description=journald-exporter
Documentation=https://github.com/dead-claudia/journald-exporter
After=network.target
AssertPathIsDirectory=/etc/journald-exporter/keys

[Install]
WantedBy=default.target

[Service]
Type=notify
ExecStart=${BINARY_PATH} --key-dir ${JOURNALD_KEYS_DIR} --port ${PORT}
WatchdogSec=5m
Restart=always
NoNewPrivileges=true
ProtectSystem=strict
ProtectClock=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectKernelLogs=true
ProtectControlGroups=true
MemoryDenyWriteExecute=true
SyslogLevel=warning
SyslogLevelPrefix=false
EOF

    chmod 644 "${SYSTEMD_UNIT_FILE}"
}

# Create system user
create_system_user() {
    echo -e "${BLUE}Creating system user...${NC}"
    if ! id -u journald-exporter >/dev/null 2>&1; then
        useradd --system --user-group journald-exporter
    else
        echo -e "${GREEN}User journald-exporter already exists.${NC}"
    fi
}

# Start and enable service
start_service() {
    echo -e "${BLUE}Starting and enabling service...${NC}"
    systemctl daemon-reload
    systemctl enable journald-exporter
    systemctl restart journald-exporter
    systemctl status --no-pager journald-exporter || true
}

# Check if service is accessible
check_service() {
    echo -e "${BLUE}Checking if service is accessible...${NC}"
    local key_content
    key_content=$(cat "${JOURNALD_KEYS_DIR}/${KEY_NAME}")

    sleep 2  # Give the service a moment to start

    if command -v curl >/dev/null 2>&1; then
        if ! curl -s --fail --user "metrics:${key_content}" "http://localhost:${PORT}/metrics" >/dev/null; then
            echo -e "${RED}Error: Service is not accessible${NC}"
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q --user=metrics --password="${key_content}" "http://localhost:${PORT}/metrics" -O /dev/null; then
            echo -e "${RED}Error: Service is not accessible${NC}"
            exit 1
        fi
    fi

    echo -e "${GREEN}Service is accessible${NC}"
}

# Print summary
print_summary() {
    local IP_ADDRESS
    IP_ADDRESS=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${BOLD}${GREEN}======== SETUP SUMMARY ========${NC}"
    echo ""

    echo -e "${BOLD}${BLUE}Configuration:${NC}"
    echo -e "  ${GREEN}•${NC} Binary path: ${MAGENTA}${BINARY_PATH}${NC}"
    echo -e "  ${GREEN}•${NC} Config directory: ${MAGENTA}${JOURNALD_CONFIG_DIR}${NC}"
    echo -e "  ${GREEN}•${NC} Keys directory: ${MAGENTA}${JOURNALD_KEYS_DIR}${NC}"
    echo -e "  ${GREEN}•${NC} API key: ${MAGENTA}${JOURNALD_KEYS_DIR}/${KEY_NAME}${NC}"
    echo -e "  ${GREEN}•${NC} Prometheus key: ${MAGENTA}${PROMETHEUS_KEYS_DIR}/journald-exporter.key${NC}"

    echo ""
    echo -e "${BOLD}${BLUE}Service Status:${NC}"
    if systemctl is-active journald-exporter >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Service is running"
    else
        echo -e "  ${RED}✗${NC} Service is not running"
    fi

    if systemctl is-enabled journald-exporter >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Service is enabled at boot"
    else
        echo -e "  ${RED}✗${NC} Service is not enabled at boot"
    fi

    echo ""
    echo -e "${BOLD}${BLUE}Access Information:${NC}"
    echo -e "  ${GREEN}•${NC} Metrics endpoint: ${MAGENTA}http://${IP_ADDRESS}:${PORT}/metrics${NC}"
    echo -e "  ${GREEN}•${NC} Username: ${MAGENTA}metrics${NC}"
    echo -e "  ${GREEN}•${NC} Password: ${MAGENTA}$(cat ${JOURNALD_KEYS_DIR}/${KEY_NAME})${NC}"

    echo ""
    echo -e "${BOLD}${BLUE}Next Steps:${NC}"
    echo -e "  ${YELLOW}1.${NC} Configure your Prometheus scraper with these settings:"
    echo -e "     - job_name: journald-exporter"
    echo -e "       basic_auth:"
    echo -e "         username: metrics"
    echo -e "         password_file: ${PROMETHEUS_KEYS_DIR}/journald-exporter.key"
    echo -e "       static_configs:"
    echo -e "       - targets:"
    echo -e "         - localhost:${PORT}"
    echo ""
    echo -e "  ${YELLOW}2.${NC} Monitor the service:"
    echo -e "     ${MAGENTA}systemctl status journald-exporter${NC}"
    echo -e "     ${MAGENTA}journalctl -u journald-exporter${NC}"
    echo ""
    echo -e "${BOLD}${GREEN}======== SETUP COMPLETE ========${NC}"
    echo ""
}

# Main installation process
main() {
    check_systemd_journald
    create_system_user
    setup_directories
    download_binary
    generate_api_key
    create_systemd_service
    start_service
    check_service
    print_summary
}

# Run main installation
main
