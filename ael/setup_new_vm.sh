#!/bin/bash
# Quick setup script for new VM

set -e

echo "=== AEL Automation - New VM Setup ==="
echo ""

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release; then
    echo "Warning: This script is designed for Ubuntu. Proceed with caution."
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install Git if not present
if ! command -v git &> /dev/null; then
    echo "Installing Git..."
    sudo apt update
    sudo apt install -y git
fi

# Install GitHub CLI if not present
if ! command -v gh &> /dev/null; then
    echo "Installing GitHub CLI..."
    sudo snap install gh
fi

# Install VS Code if not present
if ! command -v code &> /dev/null; then
    echo "Installing VS Code..."
    sudo snap install --classic code
fi

# Authenticate with GitHub
echo ""
echo "=== GitHub Authentication ==="
if ! gh auth status &> /dev/null; then
    echo "Please authenticate with GitHub:"
    gh auth login
else
    echo "Already authenticated with GitHub ✓"
fi

# Clone repository if not already cloned
REPO_DIR="$HOME/projects/ael-automation"
if [ ! -d "$REPO_DIR" ]; then
    echo ""
    echo "=== Cloning Repository ==="
    mkdir -p "$HOME/projects"
    cd "$HOME/projects"
    git clone https://github.com/bmarinipentaho/ael-automation.git
    cd ael-automation
    chmod -R +x .
else
    echo ""
    echo "Repository already exists at $REPO_DIR ✓"
    cd "$REPO_DIR"
fi

# Install VS Code extensions
echo ""
echo "=== Installing VS Code Extensions ==="
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension timonwong.shellcheck
code --install-extension eamodio.gitlens

# Install shellcheck
if ! command -v shellcheck &> /dev/null; then
    echo ""
    echo "=== Installing ShellCheck ==="
    sudo apt install -y shellcheck
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Next steps:"
echo "1. Open VS Code and sign in to GitHub Copilot:"
echo "   code $REPO_DIR"
echo ""
echo "2. Review the setup documentation:"
echo "   cat $REPO_DIR/VSCODE_SETUP.md"
echo ""
echo "3. Deploy AEL environment:"
echo "   cd $REPO_DIR"
echo "   ./deploy_ael.sh --help"
echo ""
