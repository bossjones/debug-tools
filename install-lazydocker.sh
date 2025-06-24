#!/bin/bash

# Install lazydocker - A simple terminal UI for both docker and docker-compose
# Source: https://github.com/jesseduffield/lazydocker

set -e

echo "Installing lazydocker..."
curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash

echo "lazydocker installation completed successfully!"