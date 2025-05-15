# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This repository contains a collection of debugging and utility scripts for Linux systems. The scripts are primarily focused on:

1. Installing and configuring development tools
2. System monitoring and diagnostics
3. Docker and Kubernetes management
4. Performance analysis
5. Configuration management

Most scripts are standalone Bash utilities that can be executed directly.

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

## Script Categories

The scripts in this repository can be categorized as follows:

1. **Installation scripts**: Prefixed with `install-`, these scripts automate the installation of various tools and utilities.

2. **System monitoring scripts**: Tools like `mem`, `ps-cpu`, `ps-mem`, and `check-kernel-bcc` provide diagnostics for system resources.

3. **Docker management scripts**: Tools for managing Docker containers, including configuration, logging, and maintenance.

4. **Kubernetes utilities**: Scripts prefixed with `kube` or containing `k8` help manage Kubernetes clusters.

5. **Configuration scripts**: Tools that set up or modify system configurations.

## Development Practices

When adding new scripts to this repository:

1. Ensure they have executable permissions
2. Follow the naming pattern of existing scripts
3. Include proper shebang line (e.g., `#!/bin/bash` or `#!/usr/bin/env bash`)
4. Support cross-platform usage where applicable (check for OS/architecture)
5. Include source references if the script is based on or inspired by other work