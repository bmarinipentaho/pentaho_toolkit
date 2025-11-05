#!/bin/bash
# Install GitHub CLI
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$TOOLKIT_ROOT/lib/common.sh"

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive

header "🐙 GitHub CLI Installation"

check_not_root

# Check if gh is already installed
if command_exists gh; then
    success "GitHub CLI is already installed"
    if ! confirm "Do you want to reinstall/update GitHub CLI?" "N"; then
        log "Skipping GitHub CLI installation"
        exit 0
    fi
fi

log "Installing GitHub CLI..."

# Ensure snap is available
log "Ensuring snapd is installed..."
sudo apt install -y snapd

# Install gh via snap
log "Installing gh via snap..."
sudo snap install gh

success "GitHub CLI installation completed"
log "Authenticate with: gh auth login"
