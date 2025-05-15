#!/bin/bash

#==============================================================================
# setup-journald-exporter.sh
#
# A script for installing and configuring journald-exporter on a Linux system
# with systemd. This script automates all steps of the manual installation
# process described in the official documentation.
#
# DESCRIPTION:
#   This script installs journald-exporter, a Prometheus exporter for the
#   systemd journal, and configures it as a systemd service. It handles binary
#   installation, user creation, directory setup, key generation, TLS
#   configuration, and service management.
#
# USAGE:
#   ./setup-journald-exporter.sh [OPTIONS]
#
# OPTIONS:
#   -g GROUP    Set the group that can access the API key (default: root)
#               Example: -g prometheus
#
#   -k KEY_FILE Use a pre-made key file instead of generating one
#               Example: -k /path/to/your/key
#
#   -C CERT     Path to TLS certificate (requires -K)
#               Example: -C /path/to/cert.pem
#
#   -K KEY      Path to TLS private key (requires -C)
#               Example: -K /path/to/key.pem
#
#   -p PORT     Set the port number (default: 12345)
#               Example: -p 9010
#
#   -h          Display help message
#
#   -d          Dry run mode - show what would be done without making changes
#
# EXAMPLES:
#   # Basic installation with default settings
#   ./setup-journald-exporter.sh
#
#   # Installation with custom group for Prometheus
#   ./setup-journald-exporter.sh -g prometheus
#
#   # Installation with custom port
#   ./setup-journald-exporter.sh -p 9010
#
#   # Installation with TLS for remote scraping
#   ./setup-journald-exporter.sh -C /path/to/cert.pem -K /path/to/key.pem
#
#   # Dry run to see what would happen without making changes
#   ./setup-journald-exporter.sh -d
#
#   # Complete example with all options
#   ./setup-journald-exporter.sh -g prometheus -k /path/to/key -p 9010 \
#                               -C /path/to/cert.pem -K /path/to/key.pem
#
# WHAT THIS SCRIPT DOES:
#   1. Checks if systemd-journald is running
#   2. Creates a system user 'journald-exporter'
#   3. Downloads the latest binary from GitHub
#   4. Sets up necessary directories and permissions
#   5. Generates or copies API keys
#   6. Creates and configures the systemd service
#   7. Starts and enables the service
#   8. Verifies the service is accessible
#   9. Provides a detailed summary and next steps
#
# PREREQUISITES:
#   - Linux system with systemd
#   - systemd-journald running
#   - Root/sudo privileges
#   - curl or wget for downloading
#   - openssl for key generation
#
# Based on manual installation instructions from:
# https://github.com/dead-claudia/journald-exporter/blob/main/installation.md#manual
#
# Copyright 2023 Claudia Meadows (original journald-exporter)
# Copyright 2025 Setup Script Maintainer (modifications)
#==============================================================================

# Updated setup-journald-exporter.sh
# A script for installing and configuring journald-exporter
# Based on the official manual installation steps from:
# https://github.com/dead-claudia/journald-exporter/blob/main/installation.md#manual

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
BINARY_PATH="/usr/sbin/journald-exporter"
DEFAULT_PORT=12345

# Display help
help() {
    cat >&2 <<EOF
Usage: $0 [ -g GROUP ] [ -k KEY_FILE ] [ -C CERTIFICATE ] [ -K PRIVATE_KEY ] [ -p PORT ] [ -d ]

Arguments:

-g GROUP
    The group to expose the generated or default key file to. If omitted, it
    defaults to 'root'.

-k KEY_FILE
    A pre-made key file to pre-install when setting up the server. This can be
    specified multiple times, but only the first is exposed to any specified
    group.

-C CERTIFICATE
    The path where the provisioned certificate exists. Must be specified in
    tandem with '-K PRIVATE_KEY'.

-K PRIVATE_KEY
    The path where the certificate's private key is. Must be specified in
    tandem with '-C CERTIFICATE'.

-p PORT
    The port number to use for the journald-exporter service (default: ${DEFAULT_PORT}).

-d
    Dry run mode - print what would be done without making any changes.

-h
    Display this help message.

Based on manual installation instructions from
https://github.com/dead-claudia/journald-exporter/blob/main/installation.md#manual

Copyright 2023 Claudia Meadows (original journald-exporter)
Copyright 2025 Setup Script Maintainer (modifications)

Licensed under the Apache License, Version 2.0 (the "License").
EOF
    exit "$1"
}

# Function to report errors
fail() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to check if systemd-journald is running
check_systemd_journald() {
    echo -e "${BLUE}Checking if systemd-journald is running...${NC}"
    if [[ ! -e /run/systemd/journal/socket ]]; then
        echo -e "${RED}Error: systemd-journald is not running. Please ensure both systemd and systemd-journald are running.${NC}"
        exit 1
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would verify systemd-journald is running (✓)${NC}"
    fi
}

# Function to determine which fetch command to use
get_fetch_command() {
    if command -v curl >/dev/null 2>&1; then
        echo 'curl'
    elif command -v wget >/dev/null 2>&1; then
        echo 'wget'
    else
        fail 'Neither curl nor wget detected. Please install one of them.'
    fi
}

# Download the latest journald-exporter binary
download_binary() {
    echo -e "${BLUE}Downloading journald-exporter binary...${NC}"
    local remote_url="https://github.com/dead-claudia/journald-exporter/releases/latest/download/journald-exporter"
    local client_type=$(get_fetch_command)

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would download journald-exporter from:${NC}"
        echo -e "${YELLOW}  - ${remote_url}${NC}"
        echo -e "${YELLOW}DRY RUN: Would install binary to ${BINARY_PATH} with mode 755${NC}"
        return
    fi

    case $client_type in
        curl)
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
            ;;
        wget)
            wget \
                --tries=5 \
                --timeout=5 \
                --waitretry=5 \
                --retry-connrefused \
                --output-document="${BINARY_PATH}.tmp" \
                "${remote_url}"
            ;;
    esac

    chmod 755 "${BINARY_PATH}.tmp"
    mv "${BINARY_PATH}.tmp" "${BINARY_PATH}"
    echo -e "${GREEN}Binary downloaded and installed to ${BINARY_PATH}${NC}"
}

# Create system user
create_system_user() {
    echo -e "${BLUE}Creating system user...${NC}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would create system user 'journald-exporter' with no home directory${NC}"
        return
    fi

    if ! id -u journald-exporter >/dev/null 2>&1; then
        useradd --system --user-group journald-exporter
        echo -e "${GREEN}User journald-exporter created.${NC}"
    else
        echo -e "${GREEN}User journald-exporter already exists.${NC}"
    fi
}

# Create necessary directories
setup_directories() {
    echo -e "${BLUE}Setting up directories...${NC}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would create the following directories:${NC}"
        echo -e "${YELLOW}  - ${JOURNALD_CONFIG_DIR} (mode 755)${NC}"
        echo -e "${YELLOW}  - ${JOURNALD_KEYS_DIR} (mode 755)${NC}"
        echo -e "${YELLOW}  - ${PROMETHEUS_KEYS_DIR} (mode 755)${NC}"
        return
    fi

    # Create main config directory
    mkdir -p "${JOURNALD_CONFIG_DIR}"
    chmod 755 "${JOURNALD_CONFIG_DIR}"

    # Create keys directory
    mkdir -p "${JOURNALD_KEYS_DIR}"
    chmod 755 "${JOURNALD_KEYS_DIR}"

    # Create Prometheus keys directory
    mkdir -p "${PROMETHEUS_KEYS_DIR}"
    chmod 755 "${PROMETHEUS_KEYS_DIR}"

    echo -e "${GREEN}Directories created.${NC}"
}

# Generate API key
generate_api_key() {
    local group="$1"
    local key_name="$2"
    local -a key_files=("${@:3}")

    echo -e "${BLUE}Setting up API key...${NC}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        if [[ "${#key_files[@]}" -eq 0 ]]; then
            echo -e "${YELLOW}DRY RUN: Would generate new API key with:${NC}"
            echo -e "${YELLOW}  - openssl rand -hex 32 > ${JOURNALD_KEYS_DIR}/${key_name}${NC}"
        else
            echo -e "${YELLOW}DRY RUN: Would use provided key file:${NC}"
            echo -e "${YELLOW}  - ${key_files[0]} -> ${JOURNALD_KEYS_DIR}/${key_name}${NC}"
        fi
        echo -e "${YELLOW}DRY RUN: Would set permissions to 600 on ${JOURNALD_KEYS_DIR}/${key_name}${NC}"
        echo -e "${YELLOW}DRY RUN: Would copy key to ${PROMETHEUS_KEYS_DIR}/journald-exporter.key${NC}"
        echo -e "${YELLOW}DRY RUN: Would set permissions to 640 on ${PROMETHEUS_KEYS_DIR}/journald-exporter.key${NC}"
        echo -e "${YELLOW}DRY RUN: Would set group to ${group} on ${PROMETHEUS_KEYS_DIR}/journald-exporter.key${NC}"
        return
    fi

    if [[ "${#key_files[@]}" -eq 0 ]]; then
        echo -e "${BLUE}Generating new API key...${NC}"
        openssl rand -hex 32 > "${JOURNALD_KEYS_DIR}/${key_name}"
    else
        echo -e "${BLUE}Using provided key file...${NC}"
        cp "${key_files[0]}" "${JOURNALD_KEYS_DIR}/${key_name}"
    fi

    chmod 600 "${JOURNALD_KEYS_DIR}/${key_name}"

    # Copy key for Prometheus
    cp "${JOURNALD_KEYS_DIR}/${key_name}" "${PROMETHEUS_KEYS_DIR}/journald-exporter.key"
    chmod 640 "${PROMETHEUS_KEYS_DIR}/journald-exporter.key"

    if getent group "${group}" >/dev/null; then
        chgrp "${group}" "${PROMETHEUS_KEYS_DIR}/journald-exporter.key"
        echo -e "${GREEN}Key file group set to ${group}.${NC}"
    else
        echo -e "${YELLOW}Warning: Group ${group} does not exist. Keeping default group.${NC}"
    fi

    echo -e "${GREEN}API key setup complete.${NC}"
}

# Create systemd service file
create_systemd_service() {
    local port="$1"
    local use_tls="$2"
    local cert_path="$3"
    local key_path="$4"

    echo -e "${BLUE}Creating systemd service file...${NC}"

    local exec_start="/usr/sbin/journald-exporter --key-dir ${JOURNALD_KEYS_DIR} --port ${port}"

    # Add TLS parameters if certificates are provided
    if [[ "$use_tls" -eq 1 ]]; then
        exec_start="${exec_start} --certificate ${cert_path} --private-key ${key_path}"
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would create systemd service file at ${SYSTEMD_UNIT_FILE}${NC}"
        echo -e "${YELLOW}DRY RUN: Service would use ExecStart=${exec_start}${NC}"
        echo -e "${YELLOW}DRY RUN: Would set permissions to 644 on ${SYSTEMD_UNIT_FILE}${NC}"
        return
    fi

    cat > "${SYSTEMD_UNIT_FILE}" << EOF
[Unit]
Description=journald-exporter
Documentation=https://github.com/dead-claudia/journald-exporter
# Couple conditions so it doesn't immediately bork on startup. The program also
# checks for the directory, but this avoids having to reset the failure counter
# in case it fails for whatever reason.
After=network.target
# Asserting here as it's pretty important to make sure metrics are flowing.
AssertPathIsDirectory=${JOURNALD_KEYS_DIR}

# So it'll run on startup.
[Install]
WantedBy=default.target

[Service]
Type=notify
ExecStart=${exec_start}
WatchdogSec=5m
Restart=always
# And a number of security settings to lock down the program somewhat.
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
    echo -e "${GREEN}Systemd service file created.${NC}"
}

# Start and enable the service
start_service() {
    echo -e "${BLUE}Starting and enabling service...${NC}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would run the following commands:${NC}"
        echo -e "${YELLOW}  - systemctl daemon-reload${NC}"
        echo -e "${YELLOW}  - systemctl enable journald-exporter.service${NC}"
        echo -e "${YELLOW}  - systemctl restart journald-exporter.service${NC}"
        echo -e "${YELLOW}  - systemctl status --no-pager journald-exporter.service${NC}"
        return
    fi

    systemctl daemon-reload
    systemctl enable journald-exporter.service
    systemctl restart journald-exporter.service

    echo -e "${GREEN}Service started and enabled.${NC}"
    systemctl status --no-pager journald-exporter.service || true
}

# Check if the service is accessible
check_service() {
    local port="$1"
    local key_file="$2"

    echo -e "${BLUE}Checking if service is accessible...${NC}"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Would check if service is accessible at http://localhost:${port}/metrics${NC}"
        echo -e "${YELLOW}DRY RUN: Would use basic auth with username 'metrics' and password from ${key_file}${NC}"
        return
    fi

    local key_content
    key_content=$(cat "${key_file}")

    sleep 2  # Give the service a moment to start

    local client_type=$(get_fetch_command)
    case $client_type in
        curl)
            if ! curl -s --fail --user "metrics:${key_content}" "http://localhost:${port}/metrics" >/dev/null; then
                echo -e "${RED}Error: Service is not accessible${NC}"
                exit 1
            fi
            ;;
        wget)
            if ! wget -q --user=metrics --password="${key_content}" "http://localhost:${port}/metrics" -O /dev/null; then
                echo -e "${RED}Error: Service is not accessible${NC}"
                exit 1
            fi
            ;;
    esac

    echo -e "${GREEN}Service is accessible.${NC}"
}

# Print summary
print_summary() {
    local key_file="$1"
    local port="$2"
    local use_tls="$3"
    local IP_ADDRESS
    IP_ADDRESS=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${BOLD}${GREEN}======== SETUP SUMMARY ========${NC}"
    echo ""

    echo -e "${BOLD}${BLUE}Configuration:${NC}"
    echo -e "  ${GREEN}•${NC} Binary path: ${MAGENTA}${BINARY_PATH}${NC}"
    echo -e "  ${GREEN}•${NC} Config directory: ${MAGENTA}${JOURNALD_CONFIG_DIR}${NC}"
    echo -e "  ${GREEN}•${NC} Keys directory: ${MAGENTA}${JOURNALD_KEYS_DIR}${NC}"
    echo -e "  ${GREEN}•${NC} API key: ${MAGENTA}${key_file}${NC}"
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
    if [[ "$use_tls" -eq 1 ]]; then
        echo -e "  ${GREEN}•${NC} Metrics endpoint: ${MAGENTA}https://${IP_ADDRESS}:${port}/metrics${NC}"
    else
        echo -e "  ${GREEN}•${NC} Metrics endpoint: ${MAGENTA}http://${IP_ADDRESS}:${port}/metrics${NC}"
    fi
    echo -e "  ${GREEN}•${NC} Username: ${MAGENTA}metrics${NC}"
    echo -e "  ${GREEN}•${NC} Password: ${MAGENTA}$(cat $key_file)${NC}"

    echo ""
    echo -e "${BOLD}${BLUE}Systemd Unit File (${SYSTEMD_UNIT_FILE}):${NC}"
    echo -e "${CYAN}$(cat ${SYSTEMD_UNIT_FILE})${NC}"

    echo ""
    echo -e "${BOLD}${BLUE}Next Steps:${NC}"
    echo -e "  ${YELLOW}1.${NC} Configure your Prometheus scraper with these settings:"
    echo -e "     - job_name: journald-exporter"
    echo -e "       basic_auth:"
    echo -e "         username: metrics"
    echo -e "         password_file: ${PROMETHEUS_KEYS_DIR}/journald-exporter.key"
    echo -e "       static_configs:"
    echo -e "       - targets:"
    echo -e "         - localhost:${port}"

    if [[ "$use_tls" -eq 1 ]]; then
        echo -e "       scheme: https"
    fi

    echo ""
    echo -e "  ${YELLOW}2.${NC} If planning to scrape from a remote machine, ensure port ${port} is allowed in your firewall."
    echo ""
    echo -e "  ${YELLOW}3.${NC} Monitor the service:"
    echo -e "     ${MAGENTA}systemctl status journald-exporter${NC}"
    echo -e "     ${MAGENTA}journalctl -u journald-exporter${NC}"
    echo ""
    echo -e "  ${YELLOW}4.${NC} Update the binary when needed:"
    echo -e "     ${MAGENTA}curl https://raw.githubusercontent.com/dead-claudia/journald-exporter/main/update.sh | sudo bash${NC}"
    echo ""
    echo -e "${BOLD}${GREEN}======== SETUP COMPLETE ========${NC}"
    echo ""
}

# Main installation process
main() {
    local group="root"
    local port="${DEFAULT_PORT}"
    local certificate=""
    local private_key=""
    local use_tls=0
    local -a key_files=()
    local DRY_RUN=0

    # Parse command line options
    while getopts ':K:k:g:C:p:dh' arg; do
        case "$arg" in
            g)
                # Align with Debian and Ubuntu, but with a size limit of 31 characters
                # See: https://systemd.io/USER_NAMES/
                [[ "$OPTARG" =~ ^[a-z][-a-z0-9]{0,30}$ ]] || fail 'Group name is not valid'
                group="$OPTARG"
                ;;
            k)
                [[ -f "$OPTARG" ]] || fail 'Key file must exist'
                key_files+=("$OPTARG")
                ;;
            C)
                [[ -f "$OPTARG" ]] || fail 'Certificate file must exist'
                certificate="$OPTARG"
                ;;
            K)
                [[ -f "$OPTARG" ]] || fail 'Private key file must exist'
                private_key="$OPTARG"
                ;;
            p)
                [[ "$OPTARG" =~ ^[0-9]+$ ]] || fail 'Port must be a number'
                port="$OPTARG"
                ;;
            d)
                DRY_RUN=1
                echo -e "${YELLOW}DRY RUN MODE: No changes will be made${NC}"
                ;;
            h)
                help 0
                ;;
            *)
                help 1
                ;;
        esac
    done

    # Validate arguments
    [[ -n "$certificate" && -z "$private_key" ]] &&
        fail 'If a certificate is provided, a private key must also be provided.'

    [[ -z "$certificate" && -n "$private_key" ]] &&
        fail 'If a private key is provided, a certificate must also be provided.'

    # Set TLS flag if certificate and private key are provided
    if [[ -n "$certificate" && -n "$private_key" ]]; then
        use_tls=1
    fi

    # Generate a key name using the current timestamp
    local key_name="$(date -u +'%Y-%m-%dT%H:%M:%SZ.key')"

    # Begin installation
    check_systemd_journald
    create_system_user
    setup_directories
    download_binary

    # Handle certificates if provided
    if [[ "$use_tls" -eq 1 ]]; then
        echo -e "${BLUE}Setting up TLS certificates...${NC}"

        if [[ "$DRY_RUN" -eq 1 ]]; then
            echo -e "${YELLOW}DRY RUN: Would copy TLS certificate from ${certificate} to ${JOURNALD_CONFIG_DIR}/cert.key${NC}"
            echo -e "${YELLOW}DRY RUN: Would copy TLS private key from ${private_key} to ${JOURNALD_CONFIG_DIR}/priv.key${NC}"
            echo -e "${YELLOW}DRY RUN: Would set permissions to 600 on certificate and private key${NC}"
        else
            cp "$certificate" "${JOURNALD_CONFIG_DIR}/cert.key"
            cp "$private_key" "${JOURNALD_CONFIG_DIR}/priv.key"
            chmod 600 "${JOURNALD_CONFIG_DIR}/cert.key"
            chmod 600 "${JOURNALD_CONFIG_DIR}/priv.key"
            echo -e "${GREEN}TLS certificates installed.${NC}"
        fi
    fi

    # Generate or copy API key
    generate_api_key "$group" "$key_name" "${key_files[@]}"

    # Create systemd service
    create_systemd_service "$port" "$use_tls" "${JOURNALD_CONFIG_DIR}/cert.key" "${JOURNALD_CONFIG_DIR}/priv.key"

    # Start and enable service
    start_service

    # Check if service is accessible
    check_service "$port" "${JOURNALD_KEYS_DIR}/${key_name}"

    # Print summary
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo -e "${YELLOW}DRY RUN: Installation simulation complete. No changes were made.${NC}"
    else
        print_summary "${JOURNALD_KEYS_DIR}/${key_name}" "$port" "$use_tls"
    fi
}

# Run main installation
main "$@"
