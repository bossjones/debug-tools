#!/bin/bash
# Install uv - Python package manager
# uv is an extremely fast Python package installer and resolver, written in Rust
# https://github.com/astral-sh/uv
#
# Example usage:
#   ./install-uv.sh
#   ./install-uv.sh --check
#   UV_INSTALL_DIR=/usr/local/bin ./install-uv.sh

set -e

# Default installation directory (can be overridden by environment variable)
UV_INSTALL_DIR=${UV_INSTALL_DIR:-"$HOME/.cargo/bin"}

# Platform detection
OS=$(uname -s)
ARCH=$(uname -m)

# Function to print usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Install uv - Python package manager"
    echo ""
    echo "Options:"
    echo "  -c, --check         Check if uv is already installed"
    echo "  -f, --force         Force reinstallation even if already installed"
    echo "  --skip-python       Skip automatic Python 3.12 installation"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  UV_INSTALL_DIR      Installation directory (default: \$HOME/.cargo/bin)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Install uv"
    echo "  $0 --check                           # Check if uv is installed"
    echo "  UV_INSTALL_DIR=/usr/local/bin $0     # Install to /usr/local/bin"
}

# Parse command line arguments
CHECK_ONLY=false
FORCE_INSTALL=false
SKIP_PYTHON=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--check)
            CHECK_ONLY=true
            shift
            ;;
        -f|--force)
            FORCE_INSTALL=true
            shift
            ;;
        --skip-python)
            SKIP_PYTHON=true
            shift
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

# Function to check if uv is installed
check_uv_installed() {
    if command -v uv &> /dev/null; then
        local uv_version=$(uv --version 2>/dev/null || echo "unknown")
        echo "✓ uv is already installed: $uv_version"
        echo "  Location: $(which uv)"
        return 0
    else
        echo "✗ uv is not installed"
        return 1
    fi
}

# Function to verify installation
verify_installation() {
    echo "Verifying uv installation..."
    
    # Check if uv is in PATH
    if command -v uv &> /dev/null; then
        local uv_version=$(uv --version)
        echo "✓ uv installed successfully: $uv_version"
        echo "  Location: $(which uv)"
        
        # Test basic functionality
        echo "Testing basic functionality..."
        if uv pip --help &> /dev/null; then
            echo "✓ uv pip command works"
        else
            echo "⚠ Warning: uv pip command may not be working properly"
        fi
        
        return 0
    else
        echo "✗ uv installation failed - not found in PATH"
        echo "  You may need to restart your shell or run: source ~/.bashrc"
        return 1
    fi
}

# Function to install Python 3.12 via uv
install_python_312() {
    echo ""
    echo "Installing Python 3.12 via uv..."
    
    # Check if uv is available
    if ! command -v uv &> /dev/null; then
        echo "✗ Error: uv not found in PATH, cannot install Python 3.12"
        return 1
    fi
    
    # Install Python 3.12
    echo "Running: uv python install 3.12"
    if uv python install 3.12; then
        echo "✓ Python 3.12 installation completed"
        
        # Verify Python 3.12 installation
        echo "Verifying Python 3.12 installation..."
        if uv python list | grep -q "3.12"; then
            echo "✓ Python 3.12 is available via uv"
            
            # Show installed Python versions
            echo ""
            echo "Available Python versions via uv:"
            uv python list
        else
            echo "⚠ Warning: Python 3.12 may not have installed correctly"
        fi
        
        return 0
    else
        echo "✗ Failed to install Python 3.12"
        echo "  You can try manually: uv python install 3.12"
        return 1
    fi
}

# Function to install uv
install_uv() {
    echo "Installing uv Python package manager..."
    echo "Platform: $OS $ARCH"
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        echo "Error: curl is required but not installed"
        echo "Please install curl first:"
        case "$OS" in
            Linux)
                echo "  Ubuntu/Debian: sudo apt-get install curl"
                echo "  CentOS/RHEL/Fedora: sudo yum install curl"
                ;;
            Darwin)
                echo "  macOS: curl should be pre-installed"
                ;;
        esac
        exit 1
    fi
    
    # Set installation directory environment variable for the installer
    export UV_INSTALL_DIR
    
    echo "Installing uv to: $UV_INSTALL_DIR"
    echo "Running: curl -LsSf https://astral.sh/uv/install.sh | sh"
    
    # Download and run the installation script
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        echo "✓ uv installation script completed"
    else
        echo "✗ uv installation failed"
        exit 1
    fi
    
    # Update PATH for current session if installing to default location
    if [[ "$UV_INSTALL_DIR" == "$HOME/.cargo/bin" ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
        echo "Added $HOME/.cargo/bin to PATH for current session"
    fi
}

# Main execution
echo "uv Python Package Manager Installer"
echo "===================================="

# Check if only checking installation status
if $CHECK_ONLY; then
    check_uv_installed
    exit $?
fi

# Check if already installed and not forcing
if ! $FORCE_INSTALL && check_uv_installed; then
    echo ""
    echo "uv is already installed. Use --force to reinstall."
    exit 0
fi

# Perform installation
echo ""
install_uv

echo ""
if verify_installation; then
    # Install Python 3.12 after successful uv installation (unless skipped)
    if ! $SKIP_PYTHON; then
        install_python_312  
    else
        echo "Skipping Python 3.12 installation (--skip-python specified)"
    fi
fi

echo ""
echo "✓ Installation completed!"
echo ""
echo "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Verify installation: uv --version"
echo "  3. Check Python versions: uv python list"
echo "  4. Get started: uv pip --help"
echo ""
echo "Common uv commands:"
echo "  uv python list               # List available Python versions"
echo "  uv python install 3.11      # Install additional Python versions"
echo "  uv pip install <package>     # Install a package"
echo "  uv pip list                  # List installed packages"
echo "  uv pip show <package>        # Show package information"
echo "  uv pip freeze                # Output installed packages"
echo ""
echo "For more information, visit: https://github.com/astral-sh/uv"