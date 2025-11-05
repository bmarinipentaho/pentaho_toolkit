#!/bin/bash
#
# Pentaho Development Environment Setup
# Main orchestration script for complete environment setup
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

# Auto-confirm flag
AUTO_CONFIRM=false
export AUTO_CONFIRM

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_CONFIRM=true
            export AUTO_CONFIRM
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [-y|--yes]"
            echo ""
            echo "Options:"
            echo "  -y, --yes    Auto-confirm all prompts"
            echo "  -h, --help   Show this help message"
            echo ""
            echo "This script sets up a complete Pentaho development environment:"
            echo "  1. System tools and utilities"
            echo "  2. Docker and Docker Compose"
            echo "  3. PostgreSQL database with Pentaho schemas"
            echo "  4. Portainer for container management"
            echo "  5. Pentaho UI dependencies (LibWebKitGTK)"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Main setup header
header "🚀 Pentaho Development Environment Setup"
echo "This script will set up a complete development environment with:"
echo "  • System development tools and utilities"
echo "  • Docker and Docker Compose"
echo "  • PostgreSQL database with pgAdmin web interface"
echo "  • Portainer for Docker container management"
echo "  • Pentaho UI dependencies (LibWebKitGTK 1.0)"
echo ""

if [[ "$AUTO_CONFIRM" == true ]]; then
    log "Auto-confirm enabled, proceeding with installation..."
else
    if ! confirm "Do you want to continue with the setup?" "Y"; then
        log "Setup cancelled by user"
        exit 0
    fi
fi

log "Starting development environment setup..."

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 1: System Development Tools
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 1: System Development Tools"

log "Installing development tools and utilities..."
"$SCRIPT_DIR/setup/system/install-dev-tools.sh" || die "Development tools installation failed"
success "Development tools installed"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 2: Docker Installation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 2: Docker Installation"

log "Installing Docker and Docker Compose..."
"$SCRIPT_DIR/setup/system/install-docker.sh" || die "Docker installation failed"
success "Docker installed"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 3: Environment Configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 3: Environment Configuration"

log "Configuring Pentaho environment..."
"$SCRIPT_DIR/setup/system/configure-environment.sh" || die "Environment configuration failed"
success "Environment configured"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 4: Optional Tools (VS Code, GitHub CLI)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 4: Optional Development Tools"

if [[ "$AUTO_CONFIRM" == true ]] || confirm "Install Visual Studio Code?" "Y"; then
    "$SCRIPT_DIR/setup/system/install-vscode.sh" || warning "VS Code installation failed (continuing)"
fi

if [[ "$AUTO_CONFIRM" == true ]] || confirm "Install GitHub CLI?" "Y"; then
    "$SCRIPT_DIR/setup/system/install-github-cli.sh" || warning "GitHub CLI installation failed (continuing)"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 5: PostgreSQL Database Setup
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 5: PostgreSQL Database Setup"

log "Setting up PostgreSQL with Pentaho databases..."
cd "$SCRIPT_DIR/setup/docker/postgres"

# Use sg docker -c to run with docker group permissions (needed if just added to group)
if sg docker -c "$SCRIPT_DIR/manage/postgres.sh start"; then
    success "PostgreSQL database setup completed"
else
    warning "PostgreSQL setup may have issues - check the output above"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 6: Portainer Container Management
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 6: Portainer Container Management"

log "Setting up Portainer..."
if sg docker -c "$SCRIPT_DIR/manage/portainer.sh start"; then
    success "Portainer setup completed"
else
    warning "Portainer setup may have issues - check the output above"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 7: Pentaho UI Dependencies (Optional)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 7: Pentaho UI Dependencies (Optional)"

LIBWEBKIT_DIR="$SCRIPT_DIR/../resources/packages/libwebkit"
if [[ -d "$LIBWEBKIT_DIR" ]] && ls "$LIBWEBKIT_DIR"/*.deb >/dev/null 2>&1; then
    log "Installing Pentaho UI dependencies (LibWebKitGTK 1.0)..."
    if "$SCRIPT_DIR/setup/pentaho/install-pentaho-dependencies.sh"; then
        success "Pentaho dependencies installed successfully"
    else
        warning "Pentaho dependencies installation had issues (optional component)"
    fi
else
    warning "Pentaho UI dependency packages not found (optional)"
    log "See $SCRIPT_DIR/../resources/packages/libwebkit/README.md for manual installation"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Setup Complete
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "✅ Setup Complete!"

echo ""
log "Development environment setup completed successfully!"
echo ""

header "🌐 Access Information"
echo ""
echo "📊 PostgreSQL Database"
echo "  Host: localhost"
echo "  Port: 5432"
echo "  Databases: hibernate, quartz, jackrabbit, data_type_showcase"
echo ""
echo "🌐 pgAdmin Web Interface"
echo "  URL: http://localhost:8888"
echo "  Login: admin@pentaho.com"
echo "  Password: admin"
echo ""
echo "🐳 Portainer Container Management"
echo "  Web UI: https://localhost:9443"
echo ""
echo "🛠️  Management Commands"
echo "  PostgreSQL: $SCRIPT_DIR/manage/postgres.sh [start|stop|status|logs|connect]"
echo "  Portainer: $SCRIPT_DIR/manage/portainer.sh [start|stop|status|logs]"
echo "  Java Version: $SCRIPT_DIR/utils/switch-java.sh [8|17|21]"
echo ""
echo "📚 Documentation"
echo "  Project README: $SCRIPT_DIR/../README.md"
echo "  Data Types: $SCRIPT_DIR/../docs/DATA-TYPE-SHOWCASE.md"
echo ""

warning "Note: Docker group membership changes require logout/login to take effect"
log "You can activate it temporarily with: newgrp docker"
echo ""

success "All done! Happy developing! 🎉"
