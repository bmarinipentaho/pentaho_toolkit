#!/bin/bash
# Install Visual Studio Code
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

header "📝 Visual Studio Code Installation"

check_not_root

# Check if VS Code is already installed
if command_exists code; then
    success "Visual Studio Code is already installed"
    if ! confirm "Do you want to reinstall/update VS Code?" "N"; then
        log "Skipping VS Code installation"
        exit 0
    fi
fi

log "Installing Visual Studio Code..."

# Remove any existing Microsoft repository configurations to avoid conflicts
sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /usr/share/keyrings/packages.microsoft.gpg
sudo rm -f /usr/share/keyrings/microsoft.gpg

# Download and install Microsoft GPG key
log "Adding Microsoft GPG key..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /usr/share/keyrings/
rm -f packages.microsoft.gpg

# Add VS Code repository
log "Adding VS Code repository..."
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'

# Update and install
log "Updating package index..."
sudo apt update

log "Installing VS Code..."
sudo apt install -y code

success "Visual Studio Code installation completed"
log "Launch with: code"
