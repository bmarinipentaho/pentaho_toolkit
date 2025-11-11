#!/bin/bash
# Install development tools and utilities
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$TOOLKIT_ROOT/lib/common.sh"

# Set non-interactive mode
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

header "🛠️  Development Tools Installation"

check_not_root

log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

subheader "Basic System Tools"
log "Installing basic tools..."
sudo apt install -y \
    curl \
    wget \
    unzip \
    zip \
    tar \
    ca-certificates \
    gnupg \
    lsb-release

subheader "Text Editors & File Management"
log "Installing editors and file management tools..."
sudo apt install -y \
    vim \
    nano \
    gedit \
    tree \
    mc \
    ncdu

subheader "System Monitoring Tools"
log "Installing monitoring tools..."
sudo apt install -y \
    htop \
    glances \
    iotop \
    lsof \
    strace

subheader "Network Tools"
log "Installing network utilities..."
sudo apt install -y \
    net-tools \
    telnet \
    nmap \
    openssh-client \
    dnsutils \
    traceroute \
    tcpdump \
    netcat-openbsd \
    mtr \
    iptables-persistent

subheader "Development & Version Control"
log "Installing development tools..."
sudo apt install -y \
    git \
    python3 \
    python3-pip \
    python3-venv \
    python3-lxml

subheader "Kerberos & Security Tools"
log "Installing Kerberos client tools..."
sudo apt install -y \
    krb5-user \
    krb5-config \
    krb5-admin-server \
    openssl \
    ssl-cert

subheader "Modern CLI Tools"
log "Installing modern command-line tools..."
sudo apt install -y \
    fzf \
    bat \
    ripgrep \
    fd-find \
    httpie \
    jq \
    xmlstarlet \
    pv \
    tmux \
    parallel \
    silversearcher-ag \
    postgresql-client \
    mysql-client

# Install yq via snap (not available in apt)
if command -v snap &> /dev/null; then
    log "Installing yq via snap..."
    sudo snap install yq || warning "Failed to install yq via snap"
else
    warning "snapd not available, skipping yq installation"
fi

# Try to install eza (modern ls replacement) - may not be available in all repos
log "Attempting to install optional tools..."
sudo apt install -y eza 2>/dev/null && success "eza installed" || warning "eza not available in repositories, skipping"

success "Development tools installation completed"
