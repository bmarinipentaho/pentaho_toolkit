#!/bin/bash
# Install Docker and Docker Compose
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$TOOLKIT_ROOT/lib/common.sh"

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

header "🐳 Docker Installation"

check_not_root

# Check if Docker is already installed
if command_exists docker; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    success "Docker is already installed (version $DOCKER_VERSION)"
    
    if ! confirm "Do you want to reinstall/update Docker?" "N"; then
        log "Skipping Docker installation"
        exit 0
    fi
fi

log "Installing Docker..."

# Clean up any existing repositories
sudo rm -f /etc/apt/keyrings/docker.gpg

# Add Docker's official GPG key
log "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
log "Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update apt and install Docker
log "Updating package index..."
sudo apt update

log "Installing Docker packages..."
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Add current user to docker group
log "Adding user $USER to docker group..."
sudo usermod -aG docker "$USER"

# Install standalone Docker Compose (for compatibility)
if [[ ! -f /usr/local/bin/docker-compose ]]; then
    log "Installing standalone Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    success "Standalone Docker Compose is already installed"
fi

success "Docker installation completed"
echo ""
warning "Docker group membership will be active after logout/login or running: newgrp docker"
echo ""
log "Docker version: $(docker --version)"
log "Docker Compose version: $(docker compose version)"
