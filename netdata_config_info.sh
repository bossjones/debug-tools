#!/bin/bash

# Enhanced script to collect information needed for configuring Netdata monitoring
# for Proxmox VE, ZFS pools, and S.M.A.R.T. on a Proxmox 8.4 host

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
   echo "This script must be run as root" >&2
   exit 1
fi

# Create a temporary file to store the output
OUTPUT_FILE="/tmp/netdata_config_info.txt"

# Check for available disk space (at least 10MB)
AVAIL_SPACE=$(df -m /tmp | awk 'NR==2 {print $4}')
if [ "$AVAIL_SPACE" -lt 10 ]; then
    echo "Warning: Low disk space on /tmp ($AVAIL_SPACE MB). Output might be incomplete." >&2
fi

# Start with a clean file
echo "# Netdata Configuration Information for LLMs" > $OUTPUT_FILE
echo "# Generated on $(date)" >> $OUTPUT_FILE
echo "# Generated from $(hostname)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Function to add section headers
add_section() {
    echo -e "\n## $1\n" >> $OUTPUT_FILE
    echo "Adding section: $1"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run a command with timeout and capture its output
run_command() {
    local title="$1"
    local cmd="$2"
    local timeout_duration="${3:-30}"  # Default timeout of 30 seconds
    
    echo "### $title" >> $OUTPUT_FILE
    echo "Running: $title..."
    
    echo '```' >> $OUTPUT_FILE
    
    # Check if the first word of the command exists
    local first_cmd=$(echo "$cmd" | awk '{print $1}')
    if ! command_exists "$first_cmd"; then
        echo "Command not found: $first_cmd" | tee -a $OUTPUT_FILE
        echo "This command is not available on your system." >> $OUTPUT_FILE
    else
        # Run the command with timeout
        timeout $timeout_duration bash -c "$cmd" >> $OUTPUT_FILE 2>&1
        local status=$?
        
        if [ $status -eq 124 ]; then
            echo "Command timed out after $timeout_duration seconds: $cmd" >> $OUTPUT_FILE
        elif [ $status -ne 0 ]; then
            echo "Command failed with status $status: $cmd" >> $OUTPUT_FILE
        fi
    fi
    
    echo '```' >> $OUTPUT_FILE
    echo "" >> $OUTPUT_FILE
}

# System Information
add_section "System Information"
run_command "OS Information" "cat /etc/os-release"
run_command "System Date and Time" "date"
run_command "Uptime" "uptime"
run_command "Proxmox Version" "pveversion -v" 
run_command "Kernel Information" "uname -a"
run_command "CPU Information" "lscpu | grep -E 'Model name|Socket|Thread|CPU\\(s\\)'"
run_command "Memory Information" "free -h"
run_command "Network Interfaces" "ip -br address show"

# Proxmox VE Information
add_section "Proxmox VE Information"
run_command "Proxmox Cluster Status" "pvecm status 2>/dev/null || echo 'Not in a cluster or pvecm not available'"
run_command "Proxmox Node List" "pvesh get /nodes 2>/dev/null || echo 'pvesh not available'"
run_command "Proxmox Storage List" "pvesm status 2>/dev/null || echo 'pvesm not available'"
run_command "Proxmox VM List" "qm list 2>/dev/null || echo 'No VMs found or qm not available'"
run_command "Proxmox Container List" "pct list 2>/dev/null || echo 'No containers found or pct not available'"
run_command "Proxmox Node Status" "pvesh get /nodes/$(hostname)/status 2>/dev/null || echo 'pvesh not available'"

# Check for Prometheus exporter for Proxmox
add_section "Prometheus Exporter for Proxmox"
if command_exists pve_exporter; then
    run_command "Prometheus PVE Exporter Status" "systemctl status pve_exporter 2>/dev/null || echo 'PVE exporter service not found'"
    run_command "Prometheus PVE Exporter Config" "cat /etc/default/pve_exporter 2>/dev/null || echo 'PVE exporter config not found'"
else
    echo "Prometheus PVE Exporter does not appear to be installed." | tee -a $OUTPUT_FILE
    
    # Check if there might be alternative exporters
    if command_exists curl; then
        run_command "Check Default Prometheus PVE Exporter Port" "curl -s http://localhost:9221/metrics | head -n 10 || echo 'No service detected on port 9221'"
    fi
    
    echo "For Netdata to monitor Proxmox VE, you'll need to install prometheus-pve-exporter." | tee -a $OUTPUT_FILE
    echo "Visit: https://github.com/prometheus-pve/prometheus-pve-exporter" >> $OUTPUT_FILE
fi

# Check if Netdata is already installed
add_section "Netdata Installation Status"
if command_exists netdata; then
    run_command "Netdata Version" "netdata -v"
    run_command "Netdata Service Status" "systemctl status netdata || echo 'Service status not available'"
    run_command "Netdata Main Configuration" "cat /etc/netdata/netdata.conf 2>/dev/null || echo 'Configuration file not found'"
    
    # Check for specific collector configurations
    for config in "/etc/netdata/go.d/prometheus.conf" "/etc/netdata/go.d/zfspool.conf" "/etc/netdata/go.d/smartctl.conf"; do
        if [ -f "$config" ]; then
            run_command "Existing $(basename $config)" "cat $config"
        fi
    done
else
    echo "Netdata is not installed on this system." | tee -a $OUTPUT_FILE
    if command_exists curl; then
        run_command "Check Default Netdata Port" "curl -s http://localhost:19999/api/v1/info | head -n 10 || echo 'No Netdata service detected on port 19999'"
    fi
fi

# ZFS Information
add_section "ZFS Information"
run_command "ZFS Kernel Module Status" "lsmod | grep zfs || echo 'ZFS kernel module not loaded'"
run_command "ZFS Version" "zfs --version 2>/dev/null || echo 'ZFS not installed or command not found'"

if command_exists zpool; then
    run_command "ZFS Pools List" "zpool list"
    run_command "ZFS Pools Status" "zpool status"
    run_command "ZFS Pools I/O Statistics" "zpool iostat -v"
    run_command "ZFS Datasets List" "zfs list"
    
    # Get detailed pool properties for all pools
    pools=$(zpool list -H -o name 2>/dev/null)
    if [ -n "$pools" ]; then
        for pool in $pools; do
            run_command "Properties for pool: $pool" "zpool get all $pool" 60
            run_command "Dataset properties for pool: $pool" "zfs get all $pool" 60
        done
    else
        echo "No ZFS pools found." | tee -a $OUTPUT_FILE
    fi
else
    echo "zpool command not found. ZFS tools may not be installed." | tee -a $OUTPUT_FILE
fi

# S.M.A.R.T Information
add_section "S.M.A.R.T. Information"
if command_exists smartctl; then
    run_command "smartctl Version" "smartctl --version"
    
    # Get list of disks
    run_command "Physical Disk Devices" "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL"
    
    # Check for device-mapper devices which might hide physical disks
    run_command "Device Mapper Status" "dmsetup ls || echo 'dmsetup not available'"
    
    # Get S.M.A.R.T. information for each physical disk
    disks=$(lsblk -dpno name | grep -v "loop\|sr")
    if [ -n "$disks" ]; then
        for disk in $disks; do
            run_command "S.M.A.R.T. capability for $disk" "smartctl -i $disk" 30
            
            # Only run health check if device supports SMART
            if smartctl -i $disk | grep -q "SMART support is: Enabled"; then
                run_command "S.M.A.R.T. health for $disk" "smartctl -H $disk" 30
                run_command "S.M.A.R.T. attributes for $disk" "smartctl -A $disk" 30
            fi
        done
    else
        echo "No physical disk devices found." | tee -a $OUTPUT_FILE
    fi
else
    echo "smartctl command not found. Install smartmontools to enable S.M.A.R.T. monitoring." | tee -a $OUTPUT_FILE
fi

# Hardware RAID Information (if available)
add_section "Hardware RAID Information"
if command_exists megacli; then
    run_command "MegaRAID Adapter Information" "megacli -AdpAllInfo -aAll"
elif command_exists perccli; then
    run_command "PERC RAID Adapter Information" "perccli /call show"
elif command_exists arcconf; then
    run_command "Adaptec RAID Information" "arcconf getconfig 1"
elif command_exists ssacli; then
    run_command "HPE Smart Array Information" "ssacli ctrl all show config detail"
else
    echo "No known hardware RAID utilities detected (megacli, perccli, arcconf, ssacli)." | tee -a $OUTPUT_FILE
fi

# Netdata Configuration Paths
add_section "Netdata Configuration Paths"
echo "Here are the typical configuration paths for Netdata:" | tee -a $OUTPUT_FILE
echo "- Main configuration: /etc/netdata/netdata.conf" >> $OUTPUT_FILE
echo "- Proxmox VE configuration: /etc/netdata/go.d/prometheus.conf" >> $OUTPUT_FILE
echo "- ZFS pools configuration: /etc/netdata/go.d/zfspool.conf" >> $OUTPUT_FILE
echo "- S.M.A.R.T. configuration: /etc/netdata/go.d/smartctl.conf" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Configuration Examples
add_section "Configuration Examples"

# Proxmox VE Configuration
echo "### Proxmox VE Configuration Example (prometheus.conf)" | tee -a $OUTPUT_FILE
cat << 'EOF' >> $OUTPUT_FILE
```yaml
jobs:
  - name: proxmox
    url: http://localhost:9221/metrics
    # If the exporter requires authentication, uncomment and update:
    # username: your_username
    # password: your_password
    
    # Optional: Use selector to filter specific metrics
    # selector:
    #   allow:
    #     - pattern1
    #     - pattern2
```
EOF
echo "" >> $OUTPUT_FILE

# ZFS Pool Configuration
echo "### ZFS Pool Configuration Example (zfspool.conf)" | tee -a $OUTPUT_FILE
cat << 'EOF' >> $OUTPUT_FILE
```yaml
# Global update interval (in seconds)
update_every: 10

# Note: ZFS pools are typically auto-detected if the zpool command is available.
# You usually don't need any special configuration beyond this file existing.
```
EOF
echo "" >> $OUTPUT_FILE

# S.M.A.R.T. Configuration
echo "### S.M.A.R.T. Configuration Example (smartctl.conf)" | tee -a $OUTPUT_FILE
cat << 'EOF' >> $OUTPUT_FILE
```yaml
jobs:
  - name: smartctl
    devices_poll_interval: 60  # Poll interval in seconds

    # By default, smartctl will auto-detect devices, but you can manually specify them:
    # extra_devices:
    #   - /dev/sda
    #   - /dev/sdb
    #   - /dev/nvme0n1  # NVMe devices
    
    # If some devices are failing checks or causing problems, you can exclude them:
    # device_selector:
    #   excludes:
    #     - /dev/sda  # Exclude a specific device
```
EOF
echo "" >> $OUTPUT_FILE

# Add instructions for using the output
add_section "Installation and Configuration Instructions"
cat << 'EOF' >> $OUTPUT_FILE
### 1. Install Netdata (if not already installed)

```bash
# Basic installation
bash <(curl -Ss https://get.netdata.cloud/kickstart.sh)

# Or with automatic updates enabled
bash <(curl -Ss https://get.netdata.cloud/kickstart.sh) --auto-update
```

### 2. Install Prometheus PVE Exporter (for Proxmox VE monitoring)

```bash
# Install dependencies
apt-get update
apt-get install -y python3-pip python3-dev

# Install the exporter
pip3 install prometheus-pve-exporter

# Create a service file for the exporter
cat > /etc/systemd/system/pve_exporter.service << 'END'
[Unit]
Description=Prometheus PVE Exporter
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/pve_exporter
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
END

# Create config file
mkdir -p /etc/pve_exporter
cat > /etc/pve_exporter/pve.yml << 'END'
default:
  user: root@pam
  password: your_password
  verify_ssl: false
END

# Set appropriate permissions
chmod 600 /etc/pve_exporter/pve.yml

# Start and enable the service
systemctl daemon-reload
systemctl enable pve_exporter
systemctl start pve_exporter
```

### 3. Configure Netdata Components

#### For Proxmox VE Monitoring:
```bash
cd /etc/netdata
sudo ./edit-config go.d/prometheus.conf
```

Add the configuration shown in the "Proxmox VE Configuration Example" section.

#### For ZFS Pools Monitoring:
```bash
cd /etc/netdata
sudo ./edit-config go.d/zfspool.conf
```

Add the configuration shown in the "ZFS Pool Configuration Example" section.

#### For S.M.A.R.T. Monitoring:
```bash
cd /etc/netdata
# Make sure smartmontools is installed
apt-get install -y smartmontools

# Configure Netdata S.M.A.R.T. monitoring
sudo ./edit-config go.d/smartctl.conf
```

Add the configuration shown in the "S.M.A.R.T. Configuration Example" section.

### 4. Restart Netdata to Apply Changes

```bash
sudo systemctl restart netdata
```

### 5. Verify Monitoring is Working

Visit the Netdata dashboard at:
```
http://your_server_ip:19999
```

You should see sections for:
- Proxmox VE metrics (under "prometheus/proxmox" or similar)
- ZFS pools metrics
- S.M.A.R.T. metrics for your storage devices

### 6. Troubleshooting

If any component is not showing up:

#### Check Netdata Logs:
```bash
journalctl -u netdata -f
```

#### Check Prometheus PVE Exporter:
```bash
# Test if the exporter is providing metrics
curl http://localhost:9221/metrics | head

# Check the exporter logs
journalctl -u pve_exporter -f
```

#### Test S.M.A.R.T. Capabilities:
```bash
# Check if smartctl can access your drives
smartctl -i /dev/sda
```

#### Debug Netdata Collectors:
```bash
# For ZFS pools collector
/usr/libexec/netdata/plugins.d/go.d.plugin -d -m zfspool

# For S.M.A.R.T. collector
/usr/libexec/netdata/plugins.d/go.d.plugin -d -m smartctl

# For Prometheus collector (Proxmox)
/usr/libexec/netdata/plugins.d/go.d.plugin -d -m prometheus
```
EOF

# Print the path to the output file
echo -e "\nInformation collected and saved to $OUTPUT_FILE"
echo "You can now copy the contents of this file and paste it into a Claude window for configuration assistance."
echo -e "\nReview the file for any sensitive information before sharing:"
echo "less $OUTPUT_FILE"

# Optional: Create a sanitized version without sensitive data
echo -e "\nTo create a sanitized version with hostnames and IPs masked, run:"
echo "sed 's/[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/XXX.XXX.XXX.XXX/g; s/$(hostname)/HOSTNAME/g' $OUTPUT_FILE > ${OUTPUT_FILE%.txt}_sanitized.txt"