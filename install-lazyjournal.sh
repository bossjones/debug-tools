#!/bin/bash

# Install lazyjournal - A systemd journal viewer
# Source: https://github.com/Lifailon/lazyjournal

set -e

echo "Installing lazyjournal..."
curl -sS https://raw.githubusercontent.com/Lifailon/lazyjournal/main/install.sh | bash

echo "lazyjournal installation completed successfully!"