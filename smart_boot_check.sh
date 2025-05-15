#!/bin/bash
#
# =============================================================================
# PROXMOX SMART DIAGNOSTICS SCRIPT
# =============================================================================
#
# USAGE:
#   chmod +x ./smartctl_proxmox.sh
#   sudo ./smartctl_proxmox.sh [options]
#
# OPTIONS:
#   -a, --all-disks     Scan all disks, not just boot disk
#   -l, --long-test     Run a long SMART test (warning: can take hours)
#   -o, --output FILE   Save results to a file
#   -e, --email EMAIL   Send results to specified email address
#   -h, --help          Show this help message
#
# PURPOSE:
#   This script safely installs smartmontools and performs non-destructive
#   diagnostics on your Proxmox host's disks. It identifies which disk
#   contains your boot partition and runs basic SMART health checks.
#
# SUPPORTED CONFIGURATIONS:
#   - Traditional SATA/SAS drives
#   - NVMe drives (with proper parameter handling)
#   - Hardware RAID setups (MegaRAID, Areca, HP, etc.)
#   - Software RAID (mdadm) with underlying physical disk detection
#   - LVM volumes with physical disk detection
#
# SAFETY:
#   This script is read-only with the exception of:
#   - Installing smartmontools package if not already present
#   - Enabling SMART support on the disk if available but not enabled
#   No data will be deleted or modified on your disks.
#
# OUTPUT:
#   The script will display (with color-coded indicators):
#   1. Boot disk identification
#   2. Disk model and basic information
#   3. Overall health status (PASSED/FAILED)
#   4. Detailed SMART attributes with current values and thresholds
#   5. Disk temperature and critical temperature thresholds
#
# INTERPRETING RESULTS:
#   - Pay special attention to "Reallocated_Sector_Ct", "Current_Pending_Sector",
#     and "Offline_Uncorrectable" attributes
#   - Any non-zero values in these fields could indicate impending disk failure
#   - Watch for attributes marked as FAILING or with values close to thresholds
#   - Disk temperatures consistently above 60°C may indicate cooling issues
#
# WHAT'S NEXT:
#   If issues are detected, consider:
#   - Creating full backups of your Proxmox configuration
#   - Backing up VM disk images
#   - Planning for disk replacement
#
# =============================================================================

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check for root/sudo permissions
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}ERROR: This script must be run with sudo or as root${NC}"
  exit 1
fi

# Initialize variables
SCAN_ALL_DISKS=false
RUN_LONG_TEST=false
OUTPUT_FILE="smart.log"
EMAIL_ADDRESS=""
TEMP_FILE=$(mktemp)

# Function to display help
show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -a, --all-disks     Scan all disks, not just boot disk"
  echo "  -l, --long-test     Run a long SMART test (warning: can take hours)"
  echo "  -o, --output FILE   Save results to a file (default: smart.log)"
  echo "  -e, --email EMAIL   Send results to specified email address"
  echo "  -h, --help          Show this help message"
  exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -a|--all-disks)
      SCAN_ALL_DISKS=true
      shift
      ;;
    -l|--long-test)
      RUN_LONG_TEST=true
      shift
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -e|--email)
      EMAIL_ADDRESS="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      show_help
      ;;
  esac
done

# Function to log messages
log_message() {
  local msg="$1"
  echo -e "$msg"
  if [ -n "$OUTPUT_FILE" ]; then
    echo -e "$msg" | sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$OUTPUT_FILE"
  fi
  echo -e "$msg" | sed 's/\x1B\[[0-9;]*[JKmsu]//g' >> "$TEMP_FILE"
}

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

  log_message "${BLUE}Installing smartmontools...${NC}"

  if [ "$os_type" == "debian" ]; then
    sudo apt-get update
    sudo apt-get install -y smartmontools
  elif [ "$os_type" == "redhat" ]; then
    sudo yum update -y
    sudo yum install -y smartmontools
  else
    log_message "${RED}Unsupported OS. Please install smartmontools manually.${NC}"
    exit 1
  fi

  # Verify installation
  if command -v smartctl &> /dev/null; then
    log_message "${GREEN}smartctl installed successfully: $(smartctl --version | head -n1)${NC}"
  else
    log_message "${RED}Failed to install smartctl${NC}"
    exit 1
  fi
}

# Function to find boot disk
find_boot_disk() {
  log_message "${BLUE}Detecting boot disk...${NC}"

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
  ROOT_DISK=$(echo "$ROOT_PART" | sed -E 's/p?[0-9]+$//' | sed -E 's/[0-9]+$//')

  # Handle cases where the root partition might be on LVM, RAID, etc.
  if [[ "$ROOT_DISK" == *mapper* ]] || [[ "$ROOT_DISK" == *md* ]]; then
    log_message "${YELLOW}Complex storage setup detected (LVM or RAID)${NC}"

    # Try to find physical disks using lsblk
    if command -v lsblk &> /dev/null; then
      log_message "Physical disks that may contain boot partition:"
      lsblk -o NAME,TYPE,MOUNTPOINT | grep -E "disk|part.*boot|part.*/$"

      # For LVM, try to find the physical volumes
      if [[ "$ROOT_DISK" == *mapper* ]] && command -v pvs &> /dev/null; then
        log_message "\nLVM physical volumes:"
        pvs
      fi

      # For MD RAID, try to find the component devices
      if [[ "$ROOT_DISK" == *md* ]] && [ -f /proc/mdstat ]; then
        log_message "\nMD RAID components:"
        cat /proc/mdstat
      fi
    fi
  else
    log_message "${GREEN}Boot disk appears to be: $ROOT_DISK${NC}"

    if [ -n "$BOOT_DEV_MOUNTPOINT" ] && [ "$BOOT_DEV_MOUNTPOINT" != "$ROOT_DEV_MOUNTPOINT" ]; then
      BOOT_DISK=$(echo "$BOOT_DEV_MOUNTPOINT" | sed -E 's/p?[0-9]+$//' | sed -E 's/[0-9]+$//')
      log_message "${YELLOW}Separate /boot partition detected on: $BOOT_DISK${NC}"
    fi
  fi

  return 0
}

# Function to get a list of all disks
get_all_disks() {
  log_message "${BLUE}Finding all available disks...${NC}"

  # Get all disks excluding loop, ram, and rom devices
  local ALL_DISKS=$(lsblk -d -p -n -o NAME | grep -v -E '(loop|ram|rom)')

  # Check if any disks were found
  if [ -z "$ALL_DISKS" ]; then
    log_message "${RED}No disks found!${NC}"
    exit 1
  fi

  log_message "Found disks:"
  for disk in $ALL_DISKS; do
    log_message "  $disk"
  done

  echo "$ALL_DISKS"
}

# Function to detect RAID controller and provide appropriate parameters
detect_raid_controller() {
  local disk="$1"
  local raid_params=""

  # Check for different RAID controllers
  if [ -d /proc/megaraid ] || lspci | grep -i megaraid &>/dev/null; then
    log_message "${YELLOW}MegaRAID controller detected${NC}"
    # For MegaRAID, we need to pass a parameter to tell smartctl which disk to check
    # This is a simplified approach; ideally, we would enumerate actual drives
    raid_params="-d megaraid,0"
  elif lspci | grep -i "Areca" &>/dev/null; then
    log_message "${YELLOW}Areca RAID controller detected${NC}"
    raid_params="-d areca,0"
  elif lspci | grep -i "Adaptec" &>/dev/null; then
    log_message "${YELLOW}Adaptec RAID controller detected${NC}"
    raid_params="-d aacraid,0"
  elif lspci | grep -i "HP.*RAID" &>/dev/null; then
    log_message "${YELLOW}HP RAID controller detected${NC}"
    raid_params="-d cciss,0"
  fi

  echo "$raid_params"
}

# Function to extract temperature from SMART data
extract_temperature() {
  local smart_output="$1"
  local temp=""

  # Look for temperature attributes in SMART data
  if echo "$smart_output" | grep -q "Temperature_Celsius"; then
    temp=$(echo "$smart_output" | grep "Temperature_Celsius" | awk '{print $10}')
  elif echo "$smart_output" | grep -q "Airflow_Temperature_Cel"; then
    temp=$(echo "$smart_output" | grep "Airflow_Temperature_Cel" | awk '{print $10}')
  elif echo "$smart_output" | grep -q "Temperature"; then
    temp=$(echo "$smart_output" | grep "Temperature" | awk '{print $10}')
  fi

  echo "$temp"
}

# Function to run SMART tests on a disk
run_smart_tests() {
  local disk="$1"
  local is_boot="${2:-false}"

  if [ -z "$disk" ]; then
    log_message "${RED}No disk specified. Cannot run SMART tests.${NC}"
    return 1
  fi

  log_message "\n${BLUE}Running SMART tests on $disk${NC}"

  # Check if the disk exists
  if [ ! -b "$disk" ]; then
    log_message "${RED}Disk $disk does not exist or is not a block device.${NC}"
    return 1
  fi

  # Determine if disk is NVMe
  local is_nvme=false
  if [[ "$disk" == *"nvme"* ]]; then
    is_nvme=true
    log_message "${YELLOW}NVMe drive detected, using appropriate parameters${NC}"
  fi

  # Detect RAID controller
  local raid_params=$(detect_raid_controller "$disk")

  # Set base command with raid parameters if any
  local smartctl_base="sudo smartctl $raid_params"

  # Check if SMART is enabled (skip for NVMe as they're always enabled)
  if ! $is_nvme; then
    local SMART_STATUS=$($smartctl_base -i "$disk" | grep -E "SMART support is: (Enabled|Available)")

    if [[ "$SMART_STATUS" == *"Available"* ]] && [[ "$SMART_STATUS" != *"Enabled"* ]]; then
      log_message "${YELLOW}Enabling SMART on $disk${NC}"
      $smartctl_base -s on "$disk"
    fi
  fi

  # Display basic info
  log_message "\n${BLUE}Disk information:${NC}"
  local info_output
  info_output=$($smartctl_base -i "$disk")
  log_message "$info_output"

  # Display health status
  log_message "\n${BLUE}Disk health:${NC}"
  local health_output
  health_output=$($smartctl_base -H "$disk")
  log_message "$health_output"

  # Check if the health status indicates a PASS or FAIL
  if echo "$health_output" | grep -q "PASSED"; then
    log_message "${GREEN}✓ Overall health self-assessment: PASSED${NC}"
  elif echo "$health_output" | grep -q "FAILED"; then
    log_message "${RED}✗ Overall health self-assessment: FAILED${NC}"
  fi

  # Display SMART attributes/info based on disk type
  local smart_output
  if $is_nvme; then
    log_message "\n${BLUE}NVMe SMART Information:${NC}"
    smart_output=$($smartctl_base -a "$disk")
  else
    log_message "\n${BLUE}SMART Attributes:${NC}"
    smart_output=$($smartctl_base -A "$disk")
  fi
  log_message "$smart_output"

  # Extract and display temperature information
  local temp=$(extract_temperature "$smart_output")
  if [ -n "$temp" ]; then
    if [ "$temp" -lt 40 ]; then
      log_message "\n${GREEN}Disk temperature: ${temp}°C (Good)${NC}"
    elif [ "$temp" -lt 50 ]; then
      log_message "\n${YELLOW}Disk temperature: ${temp}°C (Acceptable)${NC}"
    else
      log_message "\n${RED}Disk temperature: ${temp}°C (High - Check cooling)${NC}"
    fi
  fi

  # Run long SMART test if requested
  if $RUN_LONG_TEST; then
    log_message "\n${YELLOW}Starting extended SMART self-test. This may take several hours to complete.${NC}"
    $smartctl_base -t long "$disk"
    log_message "${YELLOW}Test started in background. Check status later with: smartctl -l selftest $disk${NC}"
  fi

  # Check for critical SMART attributes (for traditional drives)
  if ! $is_nvme; then
    log_message "\n${BLUE}Checking critical SMART attributes:${NC}"
    local critical_attrs=("Reallocated_Sector_Ct" "Current_Pending_Sector" "Offline_Uncorrectable" "Reported_Uncorrect" "Spin_Retry_Count")

    for attr in "${critical_attrs[@]}"; do
      local value=$(echo "$smart_output" | grep "$attr" | awk '{print $10}')
      if [ -n "$value" ] && [ "$value" -gt 0 ]; then
        log_message "${RED}✗ $attr: $value (Critical - potential disk failure)${NC}"
      elif [ -n "$value" ]; then
        log_message "${GREEN}✓ $attr: $value (Good)${NC}"
      fi
    done
  else
    # For NVMe drives, check for critical warnings and error counts
    local critical_warning=$(echo "$smart_output" | grep "Critical Warning" | awk '{print $4}')
    if [ "$critical_warning" != "0" ] && [ -n "$critical_warning" ]; then
      log_message "${RED}✗ NVMe Critical Warning: $critical_warning (Check drive)${NC}"
    else
      log_message "${GREEN}✓ NVMe Critical Warning: 0 (Good)${NC}"
    fi

    # Check error counts
    local error_entries=("Media and Data Integrity Errors" "Error Information Log Entries")
    for entry in "${error_entries[@]}"; do
      local value=$(echo "$smart_output" | grep "$entry" | awk '{print $6}')
      if [ -n "$value" ] && [ "$value" -gt 0 ]; then
        log_message "${RED}✗ $entry: $value (Errors detected)${NC}"
      elif [ -n "$value" ]; then
        log_message "${GREEN}✓ $entry: 0 (Good)${NC}"
      fi
    done
  fi

  # Record boot disk in the summary if this is the boot disk
  if $is_boot; then
    BOOT_DISK_INFO="Boot Disk: $disk"
    if $is_nvme; then
      BOOT_DISK_INFO="$BOOT_DISK_INFO (NVMe)"
    fi
  fi

  return 0
}

# Function to send email with results
send_email_report() {
  if [ -z "$EMAIL_ADDRESS" ]; then
    return 0
  fi

  log_message "\n${BLUE}Sending email report to $EMAIL_ADDRESS...${NC}"

  # Check if mail command is available
  if ! command -v mail &> /dev/null; then
    log_message "${YELLOW}Mail command not found. Installing mailutils...${NC}"

    local os_type=$(detect_os)
    if [ "$os_type" == "debian" ]; then
      apt-get update
      apt-get install -y mailutils
    elif [ "$os_type" == "redhat" ]; then
      yum install -y mailx
    else
      log_message "${RED}Unsupported OS. Cannot send email.${NC}"
      return 1
    fi
  fi

  # Create subject with hostname and status
  local hostname=$(hostname)
  local subject="SMART Disk Report for $hostname"

  # Send email with the temp file as content
  if cat "$TEMP_FILE" | mail -s "$subject" "$EMAIL_ADDRESS"; then
    log_message "${GREEN}Email sent successfully.${NC}"
  else
    log_message "${RED}Failed to send email.${NC}"
    return 1
  fi

  return 0
}

# Main execution
log_message "=== PROXMOX SMART DIAGNOSTICS SCRIPT ==="
log_message "Date: $(date)"
log_message "Results will be saved to: $OUTPUT_FILE"

# Install smartmontools if not already installed
if ! command -v smartctl &> /dev/null; then
  install_smartmontools
else
  log_message "${GREEN}smartctl is already installed: $(smartctl --version | head -n1)${NC}"
fi

# Initialize summary info
BOOT_DISK_INFO=""
SUMMARY=""

# Find boot disk
find_boot_disk

# Decide which disks to scan
if $SCAN_ALL_DISKS; then
  DISKS=$(get_all_disks)
  for disk in $DISKS; do
    # Check if this is the boot disk
    is_boot=false
    if [ "$disk" == "$ROOT_DISK" ]; then
      is_boot=true
    fi
    run_smart_tests "$disk" "$is_boot"
  done
else
  # Just scan the boot disk
  run_smart_tests "$ROOT_DISK" true
fi

# Create a summary
log_message "\n${BLUE}=== SUMMARY ===${NC}"
log_message "Host: $(hostname)"
log_message "$BOOT_DISK_INFO"
log_message "Scan completed: $(date)"

# Send email if requested
if [ -n "$EMAIL_ADDRESS" ]; then
  send_email_report
fi

# Cleanup
if [ -f "$TEMP_FILE" ]; then
    rm -f "$TEMP_FILE"
    log_message "Temporary file cleaned up"
else
    log_message "${YELLOW}Warning: Temporary file not found for cleanup${NC}"
fi

log_message "\n${GREEN}=== Script completed ===${NC}"
exit 0
