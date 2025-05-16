#!/bin/bash

# Security Onion 2.3 Audit Script
# Created: May 16, 2025
# This script collects system information, installed packages, network configuration,
# and other important details for auditing and backup purposes.

# Create output directory with timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="so_audit_${TIMESTAMP}"
mkdir -p "$OUTPUT_DIR"

# Function to run a command and save output to a file
run_cmd() {
    echo "Running: $1"
    echo "Command: $1" > "$OUTPUT_DIR/$2"
    eval "$1" >> "$OUTPUT_DIR/$2" 2>&1
    echo -e "\n\n" >> "$OUTPUT_DIR/$2"
}

# System Information
echo "Collecting system information..."
run_cmd "uname -a" "01_system_info.txt"
run_cmd "cat /etc/os-release" "01_system_info.txt"
run_cmd "hostname -f" "01_system_info.txt"
run_cmd "uptime" "01_system_info.txt"
run_cmd "free -h" "01_system_info.txt"
run_cmd "df -h" "01_system_info.txt"
run_cmd "lscpu" "01_system_info.txt"
run_cmd "dmidecode -t system" "01_system_info.txt"

# Running Processes
echo "Collecting process information..."
run_cmd "ps aux" "02_processes.txt"
run_cmd "ps -eo pid,ppid,user,cmd --forest" "02_processes.txt"
run_cmd "systemctl list-units --type=service --state=running" "02_processes.txt"
run_cmd "lsof -i" "02_processes.txt"

# User Information
echo "Collecting user information..."
run_cmd "cat /etc/passwd" "03_users.txt"
run_cmd "getent passwd" "03_users.txt"
run_cmd "cat /etc/group" "03_users.txt"
run_cmd "lastlog" "03_users.txt"
run_cmd "last -n 50" "03_users.txt"
run_cmd "who" "03_users.txt"
run_cmd "w" "03_users.txt"

# Package Information
echo "Collecting package information..."
run_cmd "rpm -qa | sort" "04_packages.txt"
run_cmd "yum list installed" "04_packages.txt"
run_cmd "pip list" "04_packages.txt"
run_cmd "pip3 list" "04_packages.txt"
run_cmd "gem list" "04_packages.txt"
run_cmd "npm list -g" "04_packages.txt"

# Network Configuration
echo "Collecting network configuration..."
run_cmd "ip addr" "05_network.txt"
run_cmd "ip route" "05_network.txt"
run_cmd "netstat -tuln" "05_network.txt"
run_cmd "netstat -rn" "05_network.txt"
run_cmd "iptables -L -v -n" "05_network.txt"
run_cmd "cat /etc/hosts" "05_network.txt"
run_cmd "cat /etc/resolv.conf" "05_network.txt"
run_cmd "cat /etc/sysconfig/network-scripts/ifcfg-*" "05_network.txt"
run_cmd "nmcli con show" "05_network.txt"
run_cmd "nmcli dev show" "05_network.txt"

# Security Onion Specific Information
echo "Collecting Security Onion specific information..."
run_cmd "ls -la /opt/so/" "06_so_info.txt"
run_cmd "docker ps -a" "06_so_info.txt"
run_cmd "docker images" "06_so_info.txt"
run_cmd "so-status" "06_so_info.txt"
run_cmd "cat /opt/so/conf/salt/minion" "06_so_info.txt"
run_cmd "ls -la /nsm/" "06_so_info.txt"
run_cmd "cat /etc/salt/minion.d/logging.conf" "06_so_info.txt"

# Cron Jobs
echo "Collecting cron job information..."
run_cmd "ls -la /etc/cron*" "07_cron.txt"
run_cmd "cat /etc/crontab" "07_cron.txt"
run_cmd "for user in \$(cut -f1 -d: /etc/passwd); do crontab -l -u \$user 2>/dev/null; done" "07_cron.txt"

# Boot and Startup Information
echo "Collecting boot information..."
run_cmd "systemctl list-unit-files --type=service" "08_boot_startup.txt"
run_cmd "ls -la /etc/systemd/system/" "08_boot_startup.txt"
run_cmd "cat /etc/fstab" "08_boot_startup.txt"
run_cmd "grubby --info=ALL" "08_boot_startup.txt"
run_cmd "cat /etc/default/grub" "08_boot_startup.txt"

# Log Files Summary
echo "Collecting log file information..."
run_cmd "ls -la /var/log/" "09_logs.txt"
run_cmd "journalctl --disk-usage" "09_logs.txt"
run_cmd "grep -i error /var/log/messages | tail -n 100" "09_logs.txt"
run_cmd "grep -i fail /var/log/messages | tail -n 100" "09_logs.txt"
run_cmd "grep -i warn /var/log/messages | tail -n 100" "09_logs.txt"

# Kernel Parameters and Loaded Modules
echo "Collecting kernel information..."
run_cmd "sysctl -a" "10_kernel.txt"
run_cmd "lsmod" "10_kernel.txt"
run_cmd "dmesg" "10_kernel.txt"
run_cmd "cat /proc/cmdline" "10_kernel.txt"

# System Authentication and Authorization
echo "Collecting auth information..."
run_cmd "cat /etc/pam.d/system-auth" "11_auth.txt"
run_cmd "cat /etc/pam.d/password-auth" "11_auth.txt"
run_cmd "cat /etc/sudoers" "11_auth.txt"
run_cmd "ls -la /etc/sudoers.d/" "11_auth.txt"
run_cmd "cat /etc/sudoers.d/*" "11_auth.txt"
run_cmd "cat /etc/ssh/sshd_config" "11_auth.txt"

# File System Information
echo "Collecting filesystem information..."
run_cmd "mount" "12_filesystem.txt"
run_cmd "lsblk -f" "12_filesystem.txt"
run_cmd "fdisk -l" "12_filesystem.txt"
run_cmd "pvs" "12_filesystem.txt"
run_cmd "vgs" "12_filesystem.txt"
run_cmd "lvs" "12_filesystem.txt"
run_cmd "findmnt" "12_filesystem.txt"

# Compressed Output
echo "Creating compressed archive..."
tar -czf "so_audit_${TIMESTAMP}.tar.gz" "$OUTPUT_DIR"

echo "Audit completed. Files are in $OUTPUT_DIR and so_audit_${TIMESTAMP}.tar.gz"
