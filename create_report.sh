#!/bin/bash

# Set the output file path
REPORT_FILE="/home/pi/dev/bossjones/report.txt"

# Create or truncate the report file
echo "SYSTEM REPORT - $(date)" > $REPORT_FILE
echo "=======================================" >> $REPORT_FILE

# Section 1: Get systemd unit files
echo -e "\n\n==== SYSTEMD UNIT FILES ====\n" >> $REPORT_FILE

# Get unit file for unbound.service
echo -e "\n--- unbound.service ---\n" >> $REPORT_FILE
systemctl cat unbound.service >> $REPORT_FILE 2>&1
echo -e "\n--- unbound.service status ---\n" >> $REPORT_FILE
systemctl status unbound.service >> $REPORT_FILE 2>&1

# Get unit file for unbound_exporter.service
echo -e "\n--- unbound_exporter.service ---\n" >> $REPORT_FILE
systemctl cat unbound_exporter.service >> $REPORT_FILE 2>&1
echo -e "\n--- unbound_exporter.service status ---\n" >> $REPORT_FILE
systemctl status unbound_exporter.service >> $REPORT_FILE 2>&1

# Get unit file for systemd-journald@netdata.service
echo -e "\n--- systemd-journald@netdata.service ---\n" >> $REPORT_FILE
systemctl cat systemd-journald@netdata.service >> $REPORT_FILE 2>&1
echo -e "\n--- systemd-journald@netdata.service status ---\n" >> $REPORT_FILE
systemctl status systemd-journald@netdata.service >> $REPORT_FILE 2>&1

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
