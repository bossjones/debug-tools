# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a collection of 112+ debugging and utility scripts for Linux systems. The scripts are primarily focused on:

1. Installing and configuring development tools
2. System monitoring and diagnostics
3. Docker and Kubernetes management
4. Performance analysis
5. Configuration management

Most scripts are standalone Bash utilities that can be executed directly.

## Architecture

This is a **flat, script-centric architecture** where each script is self-contained and independent. The repository follows these key patterns:

- **Standalone Executables**: Each script can run independently without dependencies on other scripts
- **System-wide Installation**: Scripts are designed to be copied to `/usr/local/bin` for global access
- **Cross-platform Support**: Most scripts detect OS/architecture and adapt accordingly
- **Minimal Dependencies**: Scripts rely primarily on standard bash and common Unix utilities

## Installation and Setup

The repository is designed to be installed to `/usr/local/src/debug-tools` with script executables copied to `/usr/local/bin` for system-wide access.

```bash
# Clone the repository
git clone https://github.com/bossjones/debug-tools /usr/local/src/debug-tools

# Copy executables to /usr/local/bin
cd /usr/local/src/debug-tools
sudo make copy

# Setup configuration (if needed)
sudo make config
```

## Common Commands

### Working with the Repository

* Update the tools from upstream and reinstall:
  ```bash
  update-bossjones-debug-tools
  ```

* List all executable scripts:
  ```bash
  make ls
  ```

* Copy all executable scripts to /usr/local/bin:
  ```bash
  make copy
  ```

### Environment Configuration

* Configure Claude MCP servers (for Claude Code):
  ```bash
  # Dry run (show but don't execute commands)
  ./configure_claude_mcp.sh --dry-run
  
  # Actual configuration
  ./configure_claude_mcp.sh
  ```

* Install development environments:
  ```bash
  # Docker installation
  ./install-docker.sh
  
  # Python environment with pyenv
  ./install-pyenv.sh
  
  # Node.js environment
  ./install-node.sh
  
  # Go environment
  ./install-go.sh
  ```

## Script Categories and Naming Patterns

The scripts follow consistent naming patterns based on their function:

1. **Installation scripts** (43 scripts): Prefixed with `install-`, these scripts automate the installation of various tools and utilities. Support cross-platform installation with OS/architecture detection.

2. **System monitoring scripts** (15+ scripts): Tools like `mem`, `ps-cpu`, `ps-mem`, and `check-kernel-bcc` provide diagnostics for system resources. Parse `/proc` filesystem and format output for readability.

3. **Docker management scripts** (8+ scripts): Tools for managing Docker containers, including `docker-check-config.sh`, `get-all-docker-logs`, and `setup-docker-gc-cron`.

4. **Kubernetes utilities** (9 scripts): Scripts containing `kube` or `k8` help manage Kubernetes clusters, including `downgrade-kube`, `hold-kube`/`unhold-kube`, and `get-kubeadm-config.sh`.

5. **System fix scripts** (9 scripts): Prefixed with `fix-`, these repair system configurations like `fix-docker-memlock-settings.sh` and `fix-kernel-ionotify.sh`.

6. **Configuration scripts**: Tools that set up or modify system configurations, prefixed with `setup-` or `configure-`.

## Common Script Structure

Most scripts follow this pattern:

```bash
#!/bin/bash
# Description and source references

# Platform detection
OS=$(uname -s)
ARCH=$(uname -m)

# Cross-platform logic
if [[ "$OS" = "Linux" && "$ARCH" = "x86_64" ]]; then
    # Linux x86_64 specific code
elif [[ "$OS" = "Darwin" ]]; then
    # macOS specific code
elif [[ "$OS" = "Linux" && "$ARCH" = "armv7l" ]]; then
    # ARM specific code
else
    echo "Platform not supported"
    exit 1
fi
```

## Development Practices

When adding new scripts to this repository:

1. Ensure they have executable permissions (`chmod +x`)
2. Follow the naming pattern based on script category
3. Include proper shebang line (e.g., `#!/bin/bash` or `#!/usr/bin/env bash`)
4. Support cross-platform usage where applicable (check for OS/architecture)
5. Use `set -e` for exit on error handling
6. Check command availability with `command -v` before using
7. Include source references if the script is based on or inspired by other work

## Testing and Validation

Since this is a collection of system utilities:

- Test scripts on target platforms before adding to repository
- Verify cross-platform compatibility where applicable
- Ensure scripts handle missing dependencies gracefully
- Test installation procedures on clean systems