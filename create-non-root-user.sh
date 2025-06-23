#!/bin/bash
# Create a non-root user with sudo privileges
# Based on common patterns for creating development/CI users
# Supports: Ubuntu, Debian, CentOS, RHEL, Fedora, Oracle Linux, Amazon Linux, macOS
#
# Example usage:
#   # Basic usage - creates user 'pi' with defaults
#   sudo ./create-non-root-user.sh
#
#   # Create custom user
#   sudo ./create-non-root-user.sh -u developer --uid 1001
#
#   # Using environment variables
#   sudo USERNAME=jenkins USER_UID=1002 ./create-non-root-user.sh
#
#   # Custom groups
#   sudo ./create-non-root-user.sh -u developer --groups "docker,libvirt,kvm"
#
#   # Works on any supported Linux distribution:
#   # - Ubuntu/Debian: creates user in 'sudo' group
#   # - RHEL/CentOS/Oracle Linux/Fedora: creates user in 'wheel' group

set -e

# Default values (can be overridden by environment variables)
USERNAME=${USERNAME:-pi}
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
USER_PASSWORD=${USER_PASSWORD:-password}
USER_SHELL=${USER_SHELL:-/bin/bash}
USER_GROUPS=${USER_GROUPS:-"adm,sudo,dip,plugdev,tty,audio"}

# Platform detection
OS=$(uname -s)
DISTRO=""
DISTRO_VERSION=""

# Function to detect Linux distribution
detect_distro() {
    if [[ "$OS" != "Linux" ]]; then
        return
    fi
    
    # Try /etc/os-release first (most modern distributions)
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        DISTRO_VERSION="$VERSION_ID"
    # Fallback to legacy methods
    elif [[ -f /etc/redhat-release ]]; then
        if grep -q "CentOS" /etc/redhat-release; then
            DISTRO="centos"
        elif grep -q "Red Hat" /etc/redhat-release; then
            DISTRO="rhel"
        elif grep -q "Oracle Linux" /etc/redhat-release; then
            DISTRO="ol"
        elif grep -q "Fedora" /etc/redhat-release; then
            DISTRO="fedora"
        fi
        DISTRO_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        DISTRO_VERSION=$(cat /etc/debian_version)
    fi
    
    echo "Detected distribution: $DISTRO $DISTRO_VERSION"
}

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Create a non-root user with sudo privileges"
    echo ""
    echo "Options:"
    echo "  -u, --username USERNAME    Username to create (default: pi)"
    echo "  --uid UID                  User ID (default: 1000)"
    echo "  --gid GID                  Group ID (default: 1000)"
    echo "  -p, --password PASSWORD    User password (default: password)"
    echo "  -s, --shell SHELL          User shell (default: /bin/bash)"
    echo "  -g, --groups GROUPS        Comma-separated list of additional groups"
    echo "                             (default: adm,sudo,dip,plugdev,tty,audio)"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  USERNAME, USER_UID, USER_GID, USER_PASSWORD, USER_SHELL, USER_GROUPS"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Create user 'pi' with defaults"
    echo "  $0 -u developer --uid 1001           # Create user 'developer' with UID 1001"
    echo "  USERNAME=jenkins $0                   # Create user 'jenkins' using env var"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        --uid)
            USER_UID="$2"
            shift 2
            ;;
        --gid)
            USER_GID="$2"
            shift 2
            ;;
        -p|--password)
            USER_PASSWORD="$2"
            shift 2
            ;;
        -s|--shell)
            USER_SHELL="$2"
            shift 2
            ;;
        -g|--groups)
            USER_GROUPS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Detect distribution
detect_distro

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Validate shell exists
if [[ ! -f "$USER_SHELL" ]]; then
    echo "Error: Shell $USER_SHELL does not exist"
    exit 1
fi

# Function to install required packages if missing
install_requirements() {
    local missing_packages=()
    
    # Check for required commands
    if ! command -v useradd &> /dev/null; then
        missing_packages+=("shadow-utils")
    fi
    
    if ! command -v sudo &> /dev/null; then
        missing_packages+=("sudo")
    fi
    
    if [[ ${#missing_packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    echo "Installing missing packages: ${missing_packages[*]}"
    
    case "$DISTRO" in
        ubuntu|debian)
            apt-get update
            apt-get install -y "${missing_packages[@]}"
            ;;
        centos|rhel|ol|almalinux|rocky)
            if command -v dnf &> /dev/null; then
                dnf install -y "${missing_packages[@]}"
            else
                yum install -y "${missing_packages[@]}"
            fi
            ;;
        fedora)
            dnf install -y "${missing_packages[@]}"
            ;;
        amzn)
            yum install -y "${missing_packages[@]}"
            ;;
        *)
            echo "Warning: Unknown distribution, attempting to install with available package manager"
            if command -v dnf &> /dev/null; then
                dnf install -y "${missing_packages[@]}"
            elif command -v yum &> /dev/null; then
                yum install -y "${missing_packages[@]}"
            elif command -v apt-get &> /dev/null; then
                apt-get update && apt-get install -y "${missing_packages[@]}"
            else
                echo "Error: No supported package manager found"
                exit 1
            fi
            ;;
    esac
}

# Function to get the appropriate sudo group name
get_sudo_group() {
    case "$DISTRO" in
        ubuntu|debian)
            echo "sudo"
            ;;
        centos|rhel|ol|fedora|amzn|almalinux|rocky)
            echo "wheel"
            ;;
        *)
            # Try to detect existing sudo-capable groups
            if getent group wheel &>/dev/null; then
                echo "wheel"
            elif getent group sudo &>/dev/null; then
                echo "sudo"
            else
                echo "wheel"  # Default fallback
            fi
            ;;
    esac
}

# Function to modify /etc/sudoers for NOPASSWD access
modify_sudoers_nopasswd() {
    local sudoers_file="/etc/sudoers"
    local backup_file="/etc/sudoers.backup.$(date +%Y%m%d_%H%M%S)"
    
    echo "Modifying $sudoers_file to enable NOPASSWD access"
    
    # Create backup
    cp "$sudoers_file" "$backup_file"
    echo "Created backup: $backup_file"
    
    # Create temporary file for modifications
    local temp_file="/tmp/sudoers.tmp"
    cp "$sudoers_file" "$temp_file"
    
    # Replace the patterns with NOPASSWD versions
    sed -i 's/^root[[:space:]]\+ALL=(ALL:ALL)[[:space:]]\+ALL$/root ALL=(ALL:ALL) NOPASSWD: ALL/' "$temp_file"
    sed -i 's/^%admin[[:space:]]\+ALL=(ALL)[[:space:]]\+ALL$/# Members of the admin group may gain root privileges\n%admin ALL=(ALL) NOPASSWD: ALL/' "$temp_file"
    sed -i 's/^%sudo[[:space:]]\+ALL=(ALL:ALL)[[:space:]]\+ALL$/# Allow members of group sudo to execute any command\n%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' "$temp_file"
    
    # Validate the modified sudoers file
    if visudo -c -f "$temp_file"; then
        # If validation passes, replace the original
        cp "$temp_file" "$sudoers_file"
        echo "Successfully updated $sudoers_file with NOPASSWD access"
    else
        echo "Error: Modified sudoers file failed validation"
        echo "Backup preserved at: $backup_file"
        rm -f "$temp_file"
        return 1
    fi
    
    rm -f "$temp_file"
    return 0
}

# Function to add user to additional groups
add_user_to_groups() {
    local username="$1"
    local groups="$2"
    
    if [[ -z "$groups" ]]; then
        return 0
    fi
    
    # Convert comma-separated list to array
    IFS=',' read -ra GROUP_ARRAY <<< "$groups"
    
    local added_groups=()
    local failed_groups=()
    
    for group in "${GROUP_ARRAY[@]}"; do
        # Trim whitespace
        group=$(echo "$group" | xargs)
        
        # Skip empty groups
        if [[ -z "$group" ]]; then
            continue
        fi
        
        # Check if group exists, if not try to create common ones
        if ! getent group "$group" &>/dev/null; then
            case "$group" in
                adm|dip|plugdev|tty|audio|video|games|users|input|netdev|bluetooth)
                    echo "Group '$group' doesn't exist, attempting to create it"
                    if groupadd "$group" 2>/dev/null; then
                        echo "Created group '$group'"
                    else
                        echo "Warning: Could not create group '$group'"
                        failed_groups+=("$group")
                        continue
                    fi
                    ;;
                sudo|wheel)
                    echo "Group '$group' doesn't exist, this is handled separately"
                    continue
                    ;;
                *)
                    echo "Warning: Group '$group' doesn't exist and won't be created"
                    failed_groups+=("$group")
                    continue
                    ;;
            esac
        fi
        
        # Add user to group
        if usermod -aG "$group" "$username" 2>/dev/null; then
            added_groups+=("$group")
            echo "Added $username to group '$group'"
        else
            failed_groups+=("$group")
            echo "Warning: Could not add $username to group '$group'"
        fi
    done
    
    # Report results
    if [[ ${#added_groups[@]} -gt 0 ]]; then
        echo "Successfully added to groups: ${added_groups[*]}"
    fi
    
    if [[ ${#failed_groups[@]} -gt 0 ]]; then
        echo "Failed to add to groups: ${failed_groups[*]}"
    fi
}

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
    echo "Warning: User $USERNAME already exists"
    echo "Continuing with configuration updates..."
else
    echo "Creating user $USERNAME with UID $USER_UID and GID $USER_GID"
    
    # Create group if it doesn't exist
    if ! getent group "$USERNAME" &>/dev/null; then
        groupadd -g "$USER_GID" "$USERNAME"
        echo "Created group $USERNAME with GID $USER_GID"
    fi
    
    # Create user
    useradd -m -s "$USER_SHELL" -u "$USER_UID" -g "$USERNAME" "$USERNAME"
    echo "Created user $USERNAME"
fi

# Install required packages if missing
install_requirements

# Modify /etc/sudoers for NOPASSWD access
modify_sudoers_nopasswd

# Platform-specific sudo group handling
if [[ "$OS" = "Linux" ]]; then
    SUDO_GROUP=$(get_sudo_group)
    echo "Using sudo group: $SUDO_GROUP"
    
    # Ensure sudo group exists and is configured
    if ! getent group "$SUDO_GROUP" &>/dev/null; then
        groupadd "$SUDO_GROUP"
        echo "Created $SUDO_GROUP group"
    fi
    
    # Configure sudo group permissions if not already configured
    SUDO_CONFIG_FILE="/etc/sudoers.d/$SUDO_GROUP-group"
    if [[ ! -f "$SUDO_CONFIG_FILE" ]]; then
        case "$SUDO_GROUP" in
            wheel)
                echo "%wheel ALL=(ALL) ALL" > "$SUDO_CONFIG_FILE"
                ;;
            sudo)
                echo "%sudo ALL=(ALL:ALL) ALL" > "$SUDO_CONFIG_FILE"
                ;;
        esac
        chmod 0440 "$SUDO_CONFIG_FILE"
        echo "Configured $SUDO_GROUP group sudo permissions"
    fi
    
    # Add user to sudo group
    usermod -aG "$SUDO_GROUP" "$USERNAME"
    echo "Added $USERNAME to $SUDO_GROUP group"
    
elif [[ "$OS" = "Darwin" ]]; then
    # On macOS, add to admin group for sudo privileges
    dseditgroup -o edit -a "$USERNAME" -t user admin
    echo "Added $USERNAME to admin group (macOS)"
else
    echo "Warning: Platform $OS not specifically supported, attempting Linux-style configuration"
    SUDO_GROUP=$(get_sudo_group)
    usermod -aG "$SUDO_GROUP" "$USERNAME" 2>/dev/null || echo "Warning: Could not add to $SUDO_GROUP group"
fi

# Add user to additional groups
echo "Adding user to additional groups: $USER_GROUPS"
add_user_to_groups "$USERNAME" "$USER_GROUPS"

# Configure passwordless sudo
SUDOERS_FILE="/etc/sudoers.d/$USERNAME"
echo "Configuring passwordless sudo for $USERNAME"

# Create sudoers file with proper permissions
cat > "$SUDOERS_FILE" << EOF
# Allow $USERNAME to run any commands without password
$USERNAME ALL=(ALL) NOPASSWD: ALL
%$USERNAME ALL=(ALL) NOPASSWD: ALL
EOF

# Set proper permissions on sudoers file
chmod 0440 "$SUDOERS_FILE"
echo "Created sudoers file: $SUDOERS_FILE"

# Validate sudoers file
if ! visudo -c -f "$SUDOERS_FILE"; then
    echo "Error: Invalid sudoers configuration, removing file"
    rm -f "$SUDOERS_FILE"
    exit 1
fi

# Set user password
echo "Setting password for $USERNAME"
echo "$USERNAME:$USER_PASSWORD" | chpasswd

# Create work directory and set permissions
WORK_DIR="/home/$USERNAME/work"
mkdir -p "$WORK_DIR"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME"
chmod -R 755 "/home/$USERNAME"
echo "Created work directory: $WORK_DIR"

# Additional setup for development environments
DEV_DIRS=(".ssh" ".local" ".config" ".cache")
for dir in "${DEV_DIRS[@]}"; do
    mkdir -p "/home/$USERNAME/$dir"
    chown "$USERNAME:$USERNAME" "/home/$USERNAME/$dir"
    chmod 700 "/home/$USERNAME/$dir"
done

# SELinux context fix for RHEL-based systems
if command -v restorecon &> /dev/null && [[ -f /etc/selinux/config ]]; then
    if grep -q "SELINUX=enforcing\|SELINUX=permissive" /etc/selinux/config; then
        echo "Fixing SELinux contexts for user home directory"
        restorecon -R "/home/$USERNAME" 2>/dev/null || true
    fi
fi

# Verify user can actually use sudo
echo "Verifying sudo access..."
if sudo -u "$USERNAME" sudo -n true 2>/dev/null; then
    echo "✓ Sudo access verified"
else
    echo "⚠ Warning: Sudo access verification failed, but this may be normal"
    echo "  The user should still have sudo privileges after login"
fi

echo ""
echo "✓ User creation completed successfully!"
echo ""
echo "User Details:"
echo "  Username: $USERNAME"
echo "  UID: $USER_UID"
echo "  GID: $USER_GID"
echo "  Shell: $USER_SHELL"
echo "  Home: /home/$USERNAME"
echo "  Work Dir: $WORK_DIR"
echo "  Password: $USER_PASSWORD"
echo "  Distribution: $DISTRO $DISTRO_VERSION"
if [[ "$OS" = "Linux" ]]; then
    echo "  Sudo Group: $SUDO_GROUP"
fi
echo "  Additional Groups: $USER_GROUPS"
echo ""
echo "The user has been granted passwordless sudo privileges."
echo ""
echo "Next steps:"
echo "  1. Switch to the new user: su - $USERNAME"
echo "  2. Test sudo access: sudo whoami"
echo "  3. Change password if needed: passwd"
echo ""
echo "For SSH access, you may need to:"
echo "  1. Copy SSH keys to /home/$USERNAME/.ssh/"
echo "  2. Ensure SSH service allows the user"
echo "  3. Configure firewall if needed"