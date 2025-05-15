#!/bin/bash
#
# =============================================================================
# PROXMOX SMART DIAGNOSTICS SCRIPT
# =============================================================================
#
# USAGE:
#   chmod +x ./smartctl_proxmox.sh
#   sudo ./smartctl_proxmox.sh
#
# PURPOSE:
#   This script safely installs smartmontools and performs non-destructive
#   diagnostics on your Proxmox host's boot disk. It identifies which disk
#   contains your boot partition and runs basic SMART health checks.
#
# SAFETY:
#   This script is read-only with the exception of:
#   - Installing smartmontools package if not already present
#   - Enabling SMART support on the disk if available but not enabled
#   No data will be deleted or modified on your disks.
#
# OUTPUT:
#   The script will display:
#   1. Boot disk identification
#   2. Disk model and basic information
#   3. Overall health status (PASSED/FAILED)
#   4. Detailed SMART attributes with current values and thresholds
#
# INTERPRETING RESULTS:
#   - Pay special attention to "Reallocated_Sector_Ct", "Current_Pending_Sector",
#     and "Offline_Uncorrectable" attributes
#   - Any non-zero values in these fields could indicate impending disk failure
#   - Watch for attributes marked as FAILING or with values close to thresholds
#
# WHAT'S NEXT:
#   If issues are detected, consider:
#   - Creating full backups of your Proxmox configuration
#   - Backing up VM disk images
#   - Planning for disk replacement
#
# =============================================================================

# Function to detect OS type
detect_os() {
  if [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "redhat"
  else
    echo "unknown"
  fi
}

# Function to install smartmontools based on OS
install_smartmontools() {
  local os_type=$(detect_os)

  echo "Installing smartmontools..."

  if [ "$os_type" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y smartmontools
  elif [ "$os_type" == "redhat" ]; then
    sudo yum update -y
    sudo yum install -y smartmontools
  else
    echo "Unsupported OS. Please install smartmontools manually."
    exit 1
  fi

  # Verify installation
  if command -v smartctl &> /dev/null; then
    echo "smartctl installed successfully: $(smartctl --version | head -n1)"
  else
    echo "Failed to install smartctl"
    exit 1
  fi
}

# Function to find boot disk
find_boot_disk() {
  echo "Detecting boot disk..."

  # Method 1: Find the disk containing the root partition
  ROOT_PART=$(df -P / | tail -n 1 | awk '{print $1}')

  # Method 2: Use mountpoint to get device numbers and resolve through /dev/block
  if command -v mountpoint &> /dev/null; then
    ROOT_DEV_MOUNTPOINT=$(readlink -f /dev/block/$(mountpoint -d /))
    BOOT_DEV_MOUNTPOINT=""

    if mountpoint -q /boot; then
      BOOT_DEV_MOUNTPOINT=$(readlink -f /dev/block/$(mountpoint -d /boot))
    fi
  fi

  # Extract the disk name (remove partition number)
  ROOT_DISK=$(echo $ROOT_PART | sed -E 's/p?[0-9]+$//' | sed -E 's/[0-9]+$//')

  # Handle cases where the root partition might be on LVM, RAID, etc.
  if [[ "$ROOT_DISK" == *mapper* ]] || [[ "$ROOT_DISK" == *md* ]]; then
    echo "Complex storage setup detected (LVM or RAID)"

    # Try to find physical disks using lsblk
    if command -v lsblk &> /dev/null; then
      echo "Physical disks that may contain boot partition:"
      lsblk -o NAME,TYPE,MOUNTPOINT | grep -E "disk|part.*boot|part.*/$"
    fi
  else
    echo "Boot disk appears to be: $ROOT_DISK"

    if [ -n "$BOOT_DEV_MOUNTPOINT" ] && [ "$BOOT_DEV_MOUNTPOINT" != "$ROOT_DEV_MOUNTPOINT" ]; then
      BOOT_DISK=$(echo $BOOT_DEV_MOUNTPOINT | sed -E 's/p?[0-9]+$//' | sed -E 's/[0-9]+$//')
      echo "Separate /boot partition detected on: $BOOT_DISK"
    fi
  fi

  return 0
}

# Function to run SMART tests on detected boot disk
run_smart_tests() {
  if [ -z "$ROOT_DISK" ]; then
    echo "No boot disk detected. Cannot run SMART tests."
    return 1
  fi

  echo "Running SMART tests on $ROOT_DISK"

  # Check if SMART is enabled
  SMART_STATUS=$(sudo smartctl -i $ROOT_DISK | grep -E "SMART support is: (Enabled|Available)")

  if [[ "$SMART_STATUS" == *"Available"* ]] && [[ "$SMART_STATUS" != *"Enabled"* ]]; then
    echo "Enabling SMART on $ROOT_DISK"
    sudo smartctl -s on $ROOT_DISK
  fi

  # Display basic info
  echo "Disk information:"
  sudo smartctl -i $ROOT_DISK

  # Display health status
  echo -e "\nDisk health:"
  sudo smartctl -H $ROOT_DISK

  # Display SMART attributes
  echo -e "\nSMART attributes:"
  sudo smartctl -A $ROOT_DISK

  return 0
}

# Main execution
echo "=== SMART Tools Installation and Boot Disk Detection ==="

# Install smartmontools if not already installed
if ! command -v smartctl &> /dev/null; then
  install_smartmontools
else
  echo "smartctl is already installed: $(smartctl --version | head -n1)"
fi

# Find boot disk
find_boot_disk

# Run SMART tests on boot disk
run_smart_tests

echo "=== Script completed ==="
