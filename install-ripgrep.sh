#!/bin/bash
#
# Script to install ripgrep (rg) - a fast line-oriented search tool
# Works on various Linux distributions, with special handling for Proxmox
# Source: https://github.com/BurntSushi/ripgrep
#
# Usage: ./install-ripgrep.sh [--force] [--dry-run]
#   --force: Force installation even if ripgrep is already installed
#   --dry-run: Show what commands would be executed without running them
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Detect if script is run with sudo (skip for dry run)
if [ "$EUID" -ne 0 ] && [[ ! "$*" =~ "--dry-run" ]]; then
    echo -e "${YELLOW}This script requires root privileges. Please run with sudo.${NC}"
    exit 1
fi

# Parse arguments
FORCE=0
DRY_RUN=0
for arg in "$@"; do
    case $arg in
        --force)
            FORCE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
    esac
done

# Function to execute or simulate commands
execute() {
    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${CYAN}[DRY RUN] Would execute: $*${NC}"
        return 0
    else
        "$@"
        return $?
    fi
}

# Check if ripgrep is already installed
if command -v rg >/dev/null 2>&1 && [ $FORCE -eq 0 ]; then
    CURRENT_VERSION=$(rg --version | head -n 1 | cut -d ' ' -f 2)
    echo -e "${GREEN}ripgrep version $CURRENT_VERSION is already installed.${NC}"
    echo -e "${YELLOW}Use --force to reinstall or upgrade.${NC}"
    exit 0
fi

if [ $DRY_RUN -eq 1 ]; then
    echo -e "${CYAN}[DRY RUN] This is a simulation. No changes will be made to your system.${NC}"
fi

echo -e "${BLUE}Installing ripgrep...${NC}"

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
        echo -e "${RED}Unsupported architecture: $ARCH${NC}"
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

echo -e "${BLUE}Detected system: $OS${NC}"

# Install ripgrep based on the distribution
install_using_apt() {
    echo -e "${BLUE}Updating package lists...${NC}"
    execute apt-get update -qq

    # First try to install from official repositories
    if execute apt-cache show ripgrep >/dev/null 2>&1; then
        echo -e "${BLUE}Installing ripgrep from official repositories...${NC}"
        execute apt-get install -y ripgrep
        return 0
    fi

    # If not available in official repos, install from GitHub release
    echo -e "${BLUE}Installing ripgrep from GitHub release...${NC}"

    # Install dependencies
    execute apt-get install -y curl wget

    # Get latest release info
    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${CYAN}[DRY RUN] Would retrieve latest version from GitHub API${NC}"
        LATEST_VERSION="14.1.0"  # Use a known version for dry run
    else
        LATEST_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name": "\K[^"]+')
        if [ -z "$LATEST_VERSION" ]; then
            LATEST_VERSION="14.1.0"  # Fallback version if we can't detect latest
        fi
    fi
    echo -e "${BLUE}Latest version: $LATEST_VERSION${NC}"

    # Create a temporary directory
    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${CYAN}[DRY RUN] Would create temporary directory${NC}"
        TMP_DIR="/tmp/ripgrep-install-dry-run"
    else
        TMP_DIR=$(mktemp -d)
    fi
    echo -e "${BLUE}Using temporary directory: $TMP_DIR${NC}"

    if [ $DRY_RUN -eq 0 ]; then
        cd "$TMP_DIR"
    else
        echo -e "${CYAN}[DRY RUN] Would change to directory: $TMP_DIR${NC}"
    fi

    # Download the appropriate .deb file
    DEB_FILE="ripgrep_${LATEST_VERSION}-1_${ARCH}.deb"
    DEB_URL="https://github.com/BurntSushi/ripgrep/releases/download/${LATEST_VERSION}/${DEB_FILE}"

    echo -e "${BLUE}Downloading ${DEB_URL}...${NC}"
    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${CYAN}[DRY RUN] Would download: $DEB_URL${NC}"
    else
        if ! wget -q "$DEB_URL"; then
            echo -e "${RED}Failed to download ripgrep package. Using fallback method.${NC}"
            install_from_cargo
            return $?
        fi
    fi

    # Install the .deb file
    echo -e "${BLUE}Installing package...${NC}"
    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${CYAN}[DRY RUN] Would install DEB package: $DEB_FILE${NC}"
    else
        if ! dpkg -i "$DEB_FILE"; then
            echo -e "${RED}Failed to install package. Attempting to fix dependencies...${NC}"
            apt-get -f install -y
            if ! dpkg -i "$DEB_FILE"; then
                echo -e "${RED}Installation failed. Using fallback method.${NC}"
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
        echo -e "${CYAN}[DRY RUN] Would clean up temporary directory: $TMP_DIR${NC}"
    fi

    return 0
}

install_using_dnf() {
    echo -e "${BLUE}Installing ripgrep using DNF...${NC}"
    execute dnf install -y ripgrep
    return $?
}

install_using_yum() {
    echo -e "${BLUE}Installing ripgrep using YUM...${NC}"

    # For RHEL/CentOS, we need to add a COPR repository
    if [ $DRY_RUN -eq 1 ] || [ ! -f /etc/yum.repos.d/carlwgeorge-ripgrep-epel-7.repo ]; then
        echo -e "${BLUE}Adding ripgrep COPR repository...${NC}"
        execute yum install -y yum-utils
        execute yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo
    fi

    execute yum install -y ripgrep
    return $?
}

install_using_zypper() {
    echo -e "${BLUE}Installing ripgrep using Zypper...${NC}"
    execute zypper install -y ripgrep
    return $?
}

install_using_pacman() {
    echo -e "${BLUE}Installing ripgrep using Pacman...${NC}"
    execute pacman -S --noconfirm ripgrep
    return $?
}

install_from_cargo() {
    echo -e "${BLUE}Installing ripgrep using Cargo...${NC}"

    # Install Rust and Cargo if they're not already installed
    if [ $DRY_RUN -eq 1 ] || ! command -v cargo >/dev/null 2>&1; then
        echo -e "${BLUE}Installing Rust and Cargo...${NC}"

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
            echo -e "${CYAN}[DRY RUN] Would download and run rustup.rs installer${NC}"
        else
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
            source "$HOME/.cargo/env"
        fi
    fi

    # Install ripgrep
    execute cargo install ripgrep

    # Create a symlink if installed to a non-standard path
    if [ $DRY_RUN -eq 1 ]; then
        echo -e "${CYAN}[DRY RUN] Would create symlink if needed${NC}"
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
        echo -e "${YELLOW}Unknown distribution. Attempting to install using Cargo...${NC}"
        install_from_cargo
        ;;
esac

# Verify installation
if [ $DRY_RUN -eq 1 ]; then
    echo -e "${GREEN}Dry run completed successfully!${NC}"
    echo -e "${CYAN}[DRY RUN] Would verify ripgrep installation${NC}"
    echo -e "${BLUE}For actual installation, run the script without the --dry-run flag${NC}"
    exit 0
elif command -v rg >/dev/null 2>&1; then
    echo -e "${GREEN}ripgrep installed successfully!${NC}"
    echo -e "${BLUE}Version: $(rg --version | head -n 1)${NC}"
    echo -e "${BLUE}Usage example: rg -i 'search pattern' /path/to/search${NC}"
    exit 0
else
    echo -e "${RED}Installation failed. Please check the error messages.${NC}"
    exit 1
fi
