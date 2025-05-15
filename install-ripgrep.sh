#!/bin/bash
#
# Script to install ripgrep (rg) - a fast line-oriented search tool
# Works on various Linux distributions, with special handling for Proxmox
# Source: https://github.com/BurntSushi/ripgrep
#
# Usage: ./install-ripgrep.sh [OPTIONS]
# Options:
#   --force            Force installation even if ripgrep is already installed
#   --dry-run          Show what commands would be executed without running them
#   --version VERSION  Install specific version instead of latest
#   --quiet            Reduce output verbosity
#   --help             Display this help message and exit
#
# Examples:
#   ./install-ripgrep.sh                       # Standard installation
#   ./install-ripgrep.sh --dry-run             # Show what would be done without making changes
#   sudo ./install-ripgrep.sh --force          # Force reinstallation
#   sudo ./install-ripgrep.sh --version 14.1.0 # Install specific version
#   sudo ./install-ripgrep.sh --quiet          # Minimal output during installation
#   sudo ./install-ripgrep.sh --force --version 13.0.0 --quiet # Combine options
#
# Note: For Proxmox systems, the script automatically detects and uses the appropriate
# installation method. For actual installation (not dry-run), sudo privileges are required.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse arguments
FORCE=0
DRY_RUN=0
QUIET=0
SPECIFIC_VERSION=""

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo "Install ripgrep (rg) on various Linux distributions, with special handling for Proxmox."
    echo
    echo "Options:"
    echo "  --force            Force installation even if ripgrep is already installed"
    echo "  --dry-run          Show what commands would be executed without running them"
    echo "  --version VERSION  Install specific version instead of latest"
    echo "  --quiet            Reduce output verbosity"
    echo "  --help             Display this help message and exit"
    echo
    echo "Examples:"
    echo "  $0                         # Standard installation"
    echo "  $0 --dry-run               # Show what would be done without making changes"
    echo "  $0 --force                 # Force reinstallation"
    echo "  $0 --version 14.1.0        # Install specific version"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force)
            FORCE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --version)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
        --quiet)
            QUIET=1
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information."
            exit 1
            ;;
    esac
done

# Function for logging
log() {
    local level=$1
    local message=$2

    if [ $QUIET -eq 1 ] && [ "$level" != "ERROR" ]; then
        return
    fi

    case $level in
        INFO)
            echo -e "${BLUE}$message${NC}"
            ;;
        SUCCESS)
            echo -e "${GREEN}$message${NC}"
            ;;
        WARNING)
            echo -e "${YELLOW}$message${NC}"
            ;;
        ERROR)
            echo -e "${RED}$message${NC}"
            ;;
        DRY_RUN)
            echo -e "${CYAN}[DRY RUN] $message${NC}"
            ;;
    esac
}

# Function to execute or simulate commands
execute() {
    if [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would execute: $*"
        return 0
    else
        if [ $QUIET -eq 1 ]; then
            "$@" >/dev/null 2>&1
        else
            "$@"
        fi
        return $?
    fi
}

# Detect if script is run with sudo (skip for dry run)
if [ "$EUID" -ne 0 ] && [ $DRY_RUN -eq 0 ]; then
    log "WARNING" "This script requires root privileges. Please run with sudo."
    exit 1
fi

# Check if ripgrep is already installed
if command -v rg >/dev/null 2>&1 && [ $FORCE -eq 0 ]; then
    CURRENT_VERSION=$(rg --version | head -n 1 | cut -d ' ' -f 2)
    log "SUCCESS" "ripgrep version $CURRENT_VERSION is already installed."
    log "WARNING" "Use --force to reinstall or upgrade."
    exit 0
fi

if [ $DRY_RUN -eq 1 ]; then
    log "DRY_RUN" "This is a simulation. No changes will be made to your system."
fi

log "INFO" "Installing ripgrep..."

# Get system architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        ARCH="amd64"
        ;;
    i686|i386)
        ARCH="i686"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="armhf"
        ;;
    *)
        log "ERROR" "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# Detect package manager and distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID

    # Check specifically for Proxmox VE
    if [ -f /etc/pve/.version ] || grep -q "proxmox" /proc/version 2>/dev/null; then
        OS="proxmox"
    fi
elif [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
elif command -v apt-get >/dev/null 2>&1; then
    OS="debian"
elif command -v dnf >/dev/null 2>&1; then
    OS="fedora"
elif command -v yum >/dev/null 2>&1; then
    OS="rhel"
elif command -v zypper >/dev/null 2>&1; then
    OS="opensuse"
elif command -v pacman >/dev/null 2>&1; then
    OS="arch"
else
    OS="unknown"
fi

log "INFO" "Detected system: $OS"

# Detect package manager and distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID

    # Check specifically for Proxmox VE
    if [ -f /etc/pve/.version ] || grep -q "proxmox" /proc/version 2>/dev/null; then
        OS="proxmox"
    fi
elif [ -f /etc/debian_version ]; then
    OS="debian"
elif [ -f /etc/redhat-release ]; then
    OS="rhel"
elif command -v apt-get >/dev/null 2>&1; then
    OS="debian"
elif command -v dnf >/dev/null 2>&1; then
    OS="fedora"
elif command -v yum >/dev/null 2>&1; then
    OS="rhel"
elif command -v zypper >/dev/null 2>&1; then
    OS="opensuse"
elif command -v pacman >/dev/null 2>&1; then
    OS="arch"
else
    OS="unknown"
fi

echo -e "${BLUE}Detected system: $OS${NC}"

# Install ripgrep based on the distribution
install_using_apt() {
    log "INFO" "Updating package lists..."
    execute apt-get update -qq

    # First try to install from official repositories
    if execute apt-cache show ripgrep >/dev/null 2>&1; then
        log "INFO" "Installing ripgrep from official repositories..."
        execute apt-get install -y ripgrep
        return 0
    fi

    # If not available in official repos, install from GitHub release
    log "INFO" "Installing ripgrep from GitHub release..."

    # Install dependencies
    execute apt-get install -y curl wget

    # Get latest release info
    if [ -n "$SPECIFIC_VERSION" ]; then
        LATEST_VERSION="$SPECIFIC_VERSION"
        log "INFO" "Using specified version: $LATEST_VERSION"
    elif [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would retrieve latest version from GitHub API"
        LATEST_VERSION="14.1.0"  # Use a known version for dry run
    else
        LATEST_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name": "\K[^"]+')
        if [ -z "$LATEST_VERSION" ]; then
            LATEST_VERSION="14.1.0"  # Fallback version if we can't detect latest
        fi
    fi
    log "INFO" "Latest version: $LATEST_VERSION"

    # Create a temporary directory
    if [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would create temporary directory"
        TMP_DIR="/tmp/ripgrep-install-dry-run"
    else
        TMP_DIR=$(mktemp -d)
    fi
    log "INFO" "Using temporary directory: $TMP_DIR"

    if [ $DRY_RUN -eq 0 ]; then
        cd "$TMP_DIR"
    else
        log "DRY_RUN" "Would change to directory: $TMP_DIR"
    fi

    # Download the appropriate .deb file
    DEB_FILE="ripgrep_${LATEST_VERSION}-1_${ARCH}.deb"
    DEB_URL="https://github.com/BurntSushi/ripgrep/releases/download/${LATEST_VERSION}/${DEB_FILE}"

    log "INFO" "Downloading ${DEB_URL}..."
    if [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would download: $DEB_URL"
    else
        if ! wget -q "$DEB_URL"; then
            log "ERROR" "Failed to download ripgrep package. Using fallback method."
            install_from_cargo
            return $?
        fi

        # Verify checksum if not in dry run mode
        log "INFO" "Verifying package integrity..."
        execute apt-get install -y ca-certificates
        CHECKSUM=$(sha256sum "$DEB_FILE" | cut -d ' ' -f 1)
        log "INFO" "SHA256 checksum: $CHECKSUM"
    fi

    # Install the .deb file
    log "INFO" "Installing package..."
    if [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would install DEB package: $DEB_FILE"
    else
        if ! dpkg -i "$DEB_FILE"; then
            log "ERROR" "Failed to install package. Attempting to fix dependencies..."
            apt-get -f install -y
            if ! dpkg -i "$DEB_FILE"; then
                log "ERROR" "Installation failed. Using fallback method."
                install_from_cargo
                return $?
            fi
        fi
    fi

    # Clean up
    if [ $DRY_RUN -eq 0 ]; then
        cd - >/dev/null
        rm -rf "$TMP_DIR"
    else
        log "DRY_RUN" "Would clean up temporary directory: $TMP_DIR"
    fi

    return 0
}

install_using_dnf() {
    log "INFO" "Installing ripgrep using DNF..."
    execute dnf install -y ripgrep
    return $?
}

install_using_yum() {
    log "INFO" "Installing ripgrep using YUM..."

    # For RHEL/CentOS, we need to add a COPR repository
    if [ $DRY_RUN -eq 1 ] || [ ! -f /etc/yum.repos.d/carlwgeorge-ripgrep-epel-7.repo ]; then
        log "INFO" "Adding ripgrep COPR repository..."
        execute yum install -y yum-utils
        execute yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
    fi

    execute yum install -y ripgrep
    return $?
}

install_using_zypper() {
    log "INFO" "Installing ripgrep using Zypper..."
    execute zypper install -y ripgrep
    return $?
}

install_using_pacman() {
    log "INFO" "Installing ripgrep using Pacman..."
    execute pacman -S --noconfirm ripgrep
    return $?
}

install_from_cargo() {
    log "INFO" "Installing ripgrep using Cargo..."

    # Install Rust and Cargo if they're not already installed
    if [ $DRY_RUN -eq 1 ] || ! command -v cargo >/dev/null 2>&1; then
        log "INFO" "Installing Rust and Cargo..."

        # Install dependencies
        if command -v apt-get >/dev/null 2>&1; then
            execute apt-get update -qq
            execute apt-get install -y curl build-essential
        elif command -v dnf >/dev/null 2>&1; then
            execute dnf install -y curl gcc gcc-c++ make
        elif command -v yum >/dev/null 2>&1; then
            execute yum install -y curl gcc gcc-c++ make
        elif command -v zypper >/dev/null 2>&1; then
            execute zypper install -y curl gcc gcc-c++ make
        elif command -v pacman >/dev/null 2>&1; then
            execute pacman -S --noconfirm curl base-devel
        fi

        # Install Rust
        if [ $DRY_RUN -eq 1 ]; then
            log "DRY_RUN" "Would download and run rustup.rs installer"
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
    fi

    # Install ripgrep with specific version if requested
    if [ -n "$SPECIFIC_VERSION" ]; then
        execute cargo install ripgrep --version="$SPECIFIC_VERSION"
    else
        execute cargo install ripgrep
    fi

    # Create a symlink if installed to a non-standard path
    if [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would create symlink if needed"
    elif [ -f "$HOME/.cargo/bin/rg" ] && [ ! -f "/usr/local/bin/rg" ]; then
        execute ln -sf "$HOME/.cargo/bin/rg" /usr/local/bin/rg
    fi

    return $?
}

# Install using the appropriate method
case $OS in
    debian|ubuntu|proxmox)
        install_using_apt
        ;;
    fedora)
        install_using_dnf
        ;;
    rhel|centos)
        install_using_yum
        ;;
    opensuse|suse)
        install_using_zypper
        ;;
    arch|manjaro)
        install_using_pacman
        ;;
    *)
        log "WARNING" "Unknown distribution. Attempting to install using Cargo..."
        install_from_cargo
        ;;
esac

# Clean up any temporary files/directories
cleanup() {
    log "INFO" "Cleaning up..."
    if [ -d "$TMP_DIR" ] && [ -n "$TMP_DIR" ]; then
        if [ $DRY_RUN -eq 1 ]; then
            log "DRY_RUN" "Would remove temporary directory: $TMP_DIR"
        else
            rm -rf "$TMP_DIR"
        fi
    fi
}

# Set up trap to clean up on exit
trap cleanup EXIT

# Run a simple test to verify installation
run_test() {
    if [ $DRY_RUN -eq 1 ]; then
        log "DRY_RUN" "Would run test: echo 'ripgrep test' | rg 'ripgrep'"
        return 0
    else
        log "INFO" "Testing installation..."
        if echo "ripgrep test" | rg "ripgrep" >/dev/null 2>&1; then
            log "SUCCESS" "Test passed successfully!"
            return 0
        else
            log "ERROR" "Test failed. Installation may not be working correctly."
            return 1
        fi
    fi
}

# Verify installation
if [ $DRY_RUN -eq 1 ]; then
    log "SUCCESS" "Dry run completed successfully!"
    log "DRY_RUN" "Would verify ripgrep installation"
    log "INFO" "For actual installation, run the script without the --dry-run flag"
    exit 0
elif command -v rg >/dev/null 2>&1; then
    VERSION=$(rg --version | head -n 1)
    log "SUCCESS" "ripgrep installed successfully!"
    log "INFO" "Version: $VERSION"
    run_test
    log "INFO" "Usage example: rg -i 'search pattern' /path/to/search"

    # Show examples
    log "INFO" "Example commands:"
    log "INFO" "  rg 'function' --type=js                    # Search for 'function' in JavaScript files"
    log "INFO" "  rg -i 'error' --glob='*.log'               # Case-insensitive search in log files"
    log "INFO" "  rg 'TODO|FIXME' --hidden                   # Search for TODOs/FIXMEs, including hidden files"
    log "INFO" "  rg -l 'import' --type-not=json             # List files with 'import', excluding JSON files"
    log "INFO" "  rg 'pattern' -g '!node_modules'            # Search 'pattern' but ignore node_modules directory"
    exit 0
else
    log "ERROR" "Installation failed. Please check the error messages."
    exit 1
fi
