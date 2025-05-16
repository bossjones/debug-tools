#!/bin/bash

# ============================================================================
# System Information Collector
# ============================================================================
#
# DESCRIPTION:
#   This script collects various system information and writes it to a report
#   file. It gathers systemd unit files, package information, disk usage,
#   block device details, and process information to provide a comprehensive
#   snapshot of the system state. Additionally, it extracts and includes the
#   contents of any EnvironmentFile referenced in the systemd unit files.
#
# USAGE:
#   sudo ./create_report.sh
#
# OUTPUT:
#   The script creates a detailed report at /home/pi/dev/bossjones/report.txt
#   and displays the report contents at the end
#
# INFORMATION COLLECTED:
#   1. Systemd unit files and status for:
#      - unbound.service
#      - unbound_exporter.service
#      - systemd-journald@netdata.service
#      - Including contents of any referenced EnvironmentFile
#   2. List of installed packages (dpkg -l)
#   3. Block device information (lsblk)
#   4. Disk usage statistics (df -h)
#   5. Running processes (ps aux)
#
# REQUIREMENTS:
#   - Must be run with sudo permissions to access all required information
#   - Requires standard Linux utilities: systemctl, dpkg, lsblk, df, ps, grep
#
# AUTHOR:
#   Created on: $(date +%Y-%m-%d)
#
# ============================================================================

# Set the output file path
REPORT_FILE="/home/pi/dev/bossjones/report.txt"

# Create or truncate the report file
echo "SYSTEM REPORT - $(date)" > $REPORT_FILE
echo "=======================================" >> $REPORT_FILE

# Function to extract and append EnvironmentFile contents for a given service
extract_environment_files() {
    local service_name=$1

    # Get EnvironmentFile paths from the unit file
    echo -e "\n--- ${service_name} EnvironmentFile Contents ---\n" >> $REPORT_FILE

    # Extract EnvironmentFile paths
    env_files=$(systemctl cat ${service_name} | grep EnvironmentFile | awk -F= '{print $2}' | tr -d '[:space:]')

    if [ -z "$env_files" ]; then
        echo "No EnvironmentFile specified for ${service_name}" >> $REPORT_FILE
        return
    fi

    # Process each EnvironmentFile
    IFS=$'\n'
    for env_file in $env_files; do
        # Remove leading minus sign if present (indicates optional file)
        file_path=${env_file#-}

        echo -e "\nContents of EnvironmentFile: $file_path\n" >> $REPORT_FILE

        if [ -f "$file_path" ]; then
            cat "$file_path" >> $REPORT_FILE 2>&1
        else
            echo "EnvironmentFile not found: $file_path" >> $REPORT_FILE
        fi
    done
}

# Section 1: Get systemd unit files
echo -e "\n\n==== SYSTEMD UNIT FILES ====\n" >> $REPORT_FILE

# Process unbound.service
echo -e "\n--- unbound.service ---\n" >> $REPORT_FILE
systemctl cat unbound.service >> $REPORT_FILE 2>&1
echo -e "\n--- unbound.service status ---\n" >> $REPORT_FILE
systemctl status unbound.service >> $REPORT_FILE 2>&1
extract_environment_files "unbound.service"

# Process unbound_exporter.service
echo -e "\n--- unbound_exporter.service ---\n" >> $REPORT_FILE
systemctl cat unbound_exporter.service >> $REPORT_FILE 2>&1
echo -e "\n--- unbound_exporter.service status ---\n" >> $REPORT_FILE
systemctl status unbound_exporter.service >> $REPORT_FILE 2>&1
extract_environment_files "unbound_exporter.service"

# Process systemd-journald@netdata.service
echo -e "\n--- systemd-journald@netdata.service ---\n" >> $REPORT_FILE
systemctl cat systemd-journald@netdata.service >> $REPORT_FILE 2>&1
echo -e "\n--- systemd-journald@netdata.service status ---\n" >> $REPORT_FILE
systemctl status systemd-journald@netdata.service >> $REPORT_FILE 2>&1
extract_environment_files "systemd-journald@netdata.service"

# Section 2: Package information
echo -e "\n\n==== INSTALLED PACKAGES ====\n" >> $REPORT_FILE
sudo dpkg -l >> $REPORT_FILE 2>&1

# Section 3: Block device information
echo -e "\n\n==== BLOCK DEVICES ====\n" >> $REPORT_FILE
lsblk >> $REPORT_FILE 2>&1

# Section 4: Disk usage information
echo -e "\n\n==== DISK USAGE ====\n" >> $REPORT_FILE
df -h >> $REPORT_FILE 2>&1

# Section 5: Process information
echo -e "\n\n==== RUNNING PROCESSES ====\n" >> $REPORT_FILE
sudo ps aux >> $REPORT_FILE 2>&1

echo -e "\n\nReport completed on $(date)" >> $REPORT_FILE
echo "Report saved to $REPORT_FILE"

# Display the report contents
echo -e "\n\nDisplaying report contents:\n"
cat $REPORT_FILE

echo -e "\n\nEnd of report display"
