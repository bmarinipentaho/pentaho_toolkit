#!/bin/bash
#
# Pentaho Development Environment Setup
# Main orchestration script for complete environment setup
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
readonly TOOLKIT_ROOT

# Source common functions from shared lib
source "$TOOLKIT_ROOT/lib/common.sh"

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
            echo "  2. Java (OpenJDK 21)"
            echo "  3. Docker and Docker Compose"
            echo "  4. Environment configuration"
            echo "  5. Optional tools (VS Code, GitHub CLI)"
            echo "  6. PostgreSQL database with Pentaho schemas"
            echo "  7. Portainer for container management"
            echo "  8. Data Platform (Hadoop & Spark)"
            echo "  9. Minio S3 object storage"
            echo "  10. Pentaho UI dependencies (optional)"
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
echo "  • Java (OpenJDK 21)"
echo "  • Docker and Docker Compose"
echo "  • PostgreSQL database with pgAdmin web interface"
echo "  • Portainer for Docker container management"
echo "  • Hadoop 3.4.1 & Spark 4.0.0 data platform"
echo "  • Minio S3-compatible object storage"
echo "  • Optional: Pentaho UI dependencies"
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
# STEP 2: Java Installation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 2: Java Installation"

log "Installing Java (required for Pentaho)..."
"$SCRIPT_DIR/system/install-java.sh" || die "Java installation failed"
success "Java installed"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 3: Docker Installation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 3: Docker Installation"

log "Installing Docker and Docker Compose..."
"$SCRIPT_DIR/setup/system/install-docker.sh" || die "Docker installation failed"
success "Docker installed"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 4: Environment Configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 4: Environment Configuration"

log "Configuring Pentaho environment..."
"$SCRIPT_DIR/setup/system/configure-environment.sh" || die "Environment configuration failed"
success "Environment configured"

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 5: Optional Tools (VS Code, GitHub CLI)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 5: Optional Development Tools"

if [[ "$AUTO_CONFIRM" == true ]] || confirm "Install Visual Studio Code?" "Y"; then
    "$SCRIPT_DIR/setup/system/install-vscode.sh" || warning "VS Code installation failed (continuing)"
fi

if [[ "$AUTO_CONFIRM" == true ]] || confirm "Install GitHub CLI?" "Y"; then
    "$SCRIPT_DIR/setup/system/install-github-cli.sh" || warning "GitHub CLI installation failed (continuing)"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 6: PostgreSQL Database Setup
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
# STEP 7: Portainer Container Management
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 7: Portainer Container Management"

log "Setting up Portainer..."
if sg docker -c "$SCRIPT_DIR/manage/portainer.sh start"; then
    success "Portainer setup completed"
else
    warning "Portainer setup may have issues - check the output above"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 7: Data Platform (Hadoop & Spark) - Optional
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 7: Data Platform (Hadoop & Spark)"

if [[ "$AUTO_CONFIRM" == true ]] || confirm "Install Hadoop and Spark for big data processing?" "Y"; then
    log "Installing Hadoop 3.4.1 and Spark 4.0.0..."
    if "$TOOLKIT_ROOT/data-platform/install.sh" -y; then
        success "Data platform installed successfully"
    else
        warning "Data platform installation had issues (optional component)"
    fi
else
    log "Skipping data platform installation"
    log "You can install later with: $TOOLKIT_ROOT/data-platform/install.sh"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 8: Minio S3 Object Storage
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 8: Minio S3 Object Storage"

if [[ "$AUTO_CONFIRM" == true ]] || confirm "Install Minio S3-compatible object storage?" "Y"; then
    log "Setting up Minio S3 storage..."
    if sg docker -c "$SCRIPT_DIR/manage/minio.sh start"; then
        success "Minio setup completed"
    else
        warning "Minio setup may have issues (optional component)"
    fi
else
    log "Skipping Minio installation"
    log "You can install later with: $SCRIPT_DIR/manage/minio.sh start"
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STEP 9: Pentaho UI Dependencies (Optional)
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "STEP 9: Pentaho UI Dependencies (Optional)"

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
echo "📦 Minio S3 Object Storage"
echo "  Console: http://localhost:9001"
echo "  S3 API: http://localhost:9000"
echo "  Login: admin"
echo "  Password: password123"
echo "  Buckets: pentaho, spark-logs, ael-artifacts"
echo ""
echo "🛠️  Management Commands"
echo "  PostgreSQL: $SCRIPT_DIR/manage/postgres.sh [start|stop|status|logs|connect]"
echo "  Minio:      $SCRIPT_DIR/manage/minio.sh [start|stop|status|logs|buckets]"
echo "  Portainer:  $SCRIPT_DIR/manage/portainer.sh [start|stop|status|logs]"
echo "  Java Version: $SCRIPT_DIR/utils/switch-java.sh [8|17|21]"
if [[ -x "$TOOLKIT_ROOT/data-platform/install.sh" ]]; then
    echo "  Data Platform: $TOOLKIT_ROOT/data-platform/install.sh [--hadoop-only|--spark-only]"
fi
echo ""
echo "📚 Documentation"
echo "  Project README: $SCRIPT_DIR/../README.md"
echo "  Data Types: $SCRIPT_DIR/../docs/DATA-TYPE-SHOWCASE.md"
echo ""

warning "Note: Docker group membership changes require logout/login to take effect"
log "You can activate it temporarily with: newgrp docker"
echo ""

success "All done! Happy developing! 🎉"
