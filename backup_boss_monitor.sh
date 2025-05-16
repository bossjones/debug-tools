#!/bin/bash

# ============================================================================
# Boss Monitor Backup Script
# ============================================================================
#
# DESCRIPTION:
#   This script performs a complete backup of the Boss Monitor system.
#   It first generates a system report using create_report.sh, then
#   creates a comprehensive tar archive containing all configuration files,
#   source code, and system information.
#
# USAGE:
#   sudo ./backup_boss_monitor.sh
#
# OUTPUT:
#   - System report at /home/pi/dev/bossjones/report.txt
#   - Compressed tar archive at /home/pi/dev/bossjones/boss-monitor.tar.gz
#
# REQUIREMENTS:
#   - Must be run with sudo permissions
#   - Requires create_report.sh to be in the same directory
#
# AUTHOR:
#   Created on: $(date +%Y-%m-%d)
#
# ============================================================================

echo "Beginning Boss Monitor system backup process..."

# Step 1: Generate system report
echo "Generating system report..."
sudo ./create_report.sh

# Step 2: Change to the bossjones directory
echo "Changing to target directory..."
cd ~/dev/bossjones/

# Step 3: Create the tar archive with all specified files
echo "Creating tar archive..."
sudo tar -czf boss-monitor.tar.gz \
    /home/pi/dev/bossjones/docker-compose-prometheus/docker-compose.yml \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/traefik/traefik.yaml \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/traefik/dynamic \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/nginx/nginx-no-loki.conf \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/prometheus \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/alertmanager \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/blackbox/config \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/unpoller/up.conf \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/loki/etc/loki \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/rules \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/grafana/etc/grafana/grafana.ini \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/grafana/provisioning \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/pve_exporter/pve_exporter/pve.yaml \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/env \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/docker-compose.yaml \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/Makefile \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/journald.service \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/nmcli.yaml \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/system.scap \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/syslog-ng \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/file.out \
    /home/pi/dev/bossjones/docker-compose-prometheus/outputs/.env \
    /home/pi/dev/bossjones/docker-compose-prometheus/docker-heimdall \
    /home/pi/dev/bossjones/report.txt \
    /home/pi/.zsh_history \
    /home/pi/pihole.log \
    /home/pi/.envrc \
    /home/pi/.zshrc \
    /home/pi/.bashrc \
    /home/pi/.bash_history \
    /home/pi/.bash_logout \
    /home/pi/.bash_profile \
    /home/pi/.profile \
    /home/pi/.gitconfig

# Step 4: Change ownership of the archive to the pi user
echo "Setting file ownership..."
sudo chown pi:pi boss-monitor.tar.gz

# Step 5: Display archive information
echo "Backup archive details:"
ls -ltah boss-monitor.tar.gz

# Add timestamp to backup filename
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="boss-monitor-${TIMESTAMP}.tar.gz"

# Create a dated copy of the backup
echo "Creating timestamped backup copy as ${BACKUP_FILE}..."
cp boss-monitor.tar.gz $BACKUP_FILE
sudo chown pi:pi $BACKUP_FILE

echo "Backup process complete!"
echo "Primary backup: boss-monitor.tar.gz"
echo "Timestamped copy: $BACKUP_FILE"
