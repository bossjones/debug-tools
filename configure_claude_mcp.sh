#!/bin/bash

# =============================================================================
# USAGE:
#   ./configure_claude_mcp.sh [OPTIONS]
#
# DESCRIPTION:
#   Configures MCP (Multi-Component Protocol) servers for Claude Code using
#   settings from claude_desktop_config.json. This script automates the setup
#   of multiple MCP servers with their respective configurations, environment
#   variables, and command-line arguments.
#
# OPTIONS:
#   -d, --dry-run    Run in dry-run mode - shows commands without executing them
#
# REQUIREMENTS:
#   - jq command-line tool for JSON processing
#   - Claude Code CLI tool (will be installed if missing)
#   - Valid claude_desktop_config.json file in the same directory
#
# CONFIGURATION FILE FORMAT (claude_desktop_config.json):
#   {
#     "mcpServers": {
#       "server_name": {
#         "command": "command_to_run",
#         "args": ["arg1", "arg2"],
#         "env": {                    # Optional
#           "ENV_VAR1": "value1",
#           "ENV_VAR2": "value2"
#         }
#       }
#     }
#   }
#
# EXAMPLES:
#   # Normal execution
#   ./configure_claude_mcp.sh
#
#   # Dry run to preview changes
#   ./configure_claude_mcp.sh --dry-run
# =============================================================================

# Script to configure MCP servers from claude_desktop_config.json for Claude Code
# Author: Claude
# Date: May 15, 2025

# Parse command line arguments
DRY_RUN=false
for arg in "$@"; do
  case $arg in
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

if [ "$DRY_RUN" = true ]; then
  echo "Running in DRY RUN mode - commands will be printed but not executed"
fi

set -e  # Exit on error
echo "Starting MCP server configuration for Claude Code..."

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if Claude Code is installed (skip in dry run mode)
if [ "$DRY_RUN" = false ] && ! command_exists claude; then
  echo "Claude Code is not installed. Installing..."
  npm install -g @anthropic-ai/claude-code
fi

# Configuration paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="${SCRIPT_DIR}/claude_desktop_config.json"

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
  echo "Error: Configuration file not found at $CONFIG_FILE"
  exit 1
fi

# Parse server names from the config file
SERVER_NAMES=$(jq -r '.mcpServers | keys[]' "$CONFIG_FILE")

# Function to add MCP server
add_mcp_server() {
  local server_name=$1
  local command=$(jq -r ".mcpServers.\"$server_name\".command" "$CONFIG_FILE")
  local args=$(jq -r ".mcpServers.\"$server_name\".args | @sh" "$CONFIG_FILE" | tr -d "'")
  local env_vars=$(jq -r "if .mcpServers.\"$server_name\".env then .mcpServers.\"$server_name\".env | to_entries[] | \"-e \(.key)=\(.value)\" else \"\" end" "$CONFIG_FILE" | tr '\n' ' ')

  # Create the Claude Code MCP command
  if [ ! -z "$env_vars" ]; then
    echo "Adding MCP server '$server_name' with environment variables..."
    cmd="claude mcp add $server_name $env_vars -- $command $args"
    echo "$cmd"

    if [ "$DRY_RUN" = false ]; then
      eval $cmd || echo "Failed to add server $server_name"
    fi
  else
    echo "Adding MCP server '$server_name'..."
    cmd="claude mcp add $server_name -- $command $args"
    echo "$cmd"

    if [ "$DRY_RUN" = false ]; then
      eval $cmd || echo "Failed to add server $server_name"
    fi
  fi
}

# Config directory setup (skip in dry run mode)
if [ "$DRY_RUN" = false ]; then
  echo "Setting up Claude Code configuration directory..."
  mkdir -p ~/.claude
fi

# Configure each MCP server
echo "Configuring MCP servers one by one..."
for server in $SERVER_NAMES; do
  echo "-------------------------------------------"
  echo "Processing server: $server"
  add_mcp_server "$server"
  echo "-------------------------------------------"
done

# List all configured servers (skip in dry run mode)
if [ "$DRY_RUN" = false ]; then
  echo "Listing all configured MCP servers:"
  claude mcp list
fi

if [ "$DRY_RUN" = true ]; then
  echo "Dry run complete. No changes were made."
else
  echo "MCP server configuration complete!"
fi
