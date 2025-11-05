#!/bin/bash
#
# Pentaho Dependencies Installation Script
# Installs legacy LibWebKitGTK 1.0 required for Pentaho UI components (Spoon, Report Designer, etc.)
#

set -euo pipefail

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly PACKAGES_DIR="$SCRIPT_DIR/../resources/packages/libwebkit"

# Auto-confirm flag
AUTO_CONFIRM=false

# Logging functions
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

header() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${YELLOW}$1${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Check if running with sudo/root (we need it for apt install)
check_permissions() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        error "This script requires sudo privileges"
        error "Please run with sudo or ensure your user can sudo without password"
        exit 1
    fi
}

# Check if packages directory exists
check_packages() {
    if [[ ! -d "$PACKAGES_DIR" ]]; then
        error "Packages directory not found: $PACKAGES_DIR"
        error "Please ensure the .deb files are placed in: $PACKAGES_DIR"
        exit 1
    fi
    
    # Define required packages in installation order
    local packages=(
        "libenchant1c2a_1.6.0-11.3build1_amd64.deb"
        "libicu60_60.2-3ubuntu3.2_amd64.deb"
        "libjavascriptcoregtk-1.0-0_2.4.11-3ubuntu3_amd64.deb"
        "libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb"
        "libwebkitgtk-1.0-0_2.4.11-3ubuntu3_amd64.deb"
    )
    
    local missing=0
    for pkg in "${packages[@]}"; do
        if [[ ! -f "$PACKAGES_DIR/$pkg" ]]; then
            error "Missing package: $pkg"
            missing=1
        fi
    done
    
    if [[ $missing -eq 1 ]]; then
        error "Some required .deb files are missing from: $PACKAGES_DIR"
        error "Please download and extract all required packages"
        exit 1
    fi
    
    success "All required .deb packages found"
}

# Check if already installed
check_existing_installation() {
    if dpkg-query -W -f='${Status}' libwebkitgtk-1.0-0 2>/dev/null | /bin/grep -q "install ok installed"; then
        success "LibWebKitGTK 1.0 is already installed"
        
        if [[ "$AUTO_CONFIRM" == false ]]; then
            read -p "Do you want to reinstall/update? (y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Installation cancelled by user"
                exit 0
            fi
        else
            log "Auto-confirm mode: Skipping reinstallation (already installed)"
            return 1  # Return non-zero to signal skip installation
        fi
    fi
    return 0  # Not installed, proceed
}

# Install packages
install_packages() {
    header "Installing Pentaho Dependencies"
    
    cd "$PACKAGES_DIR"
    
    # Make packages readable
    log "Setting permissions on package files..."
    chmod 644 *.deb
    
    # Install packages in order
    log "Installing libenchant1c2a..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./libenchant1c2a_1.6.0-11.3build1_amd64.deb
    
    log "Installing libicu60..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./libicu60_60.2-3ubuntu3.2_amd64.deb
    
    log "Installing libjavascriptcoregtk-1.0-0..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./libjavascriptcoregtk-1.0-0_2.4.11-3ubuntu3_amd64.deb
    
    log "Installing libwebp6..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb
    
    log "Installing libwebkitgtk-1.0-0..."
    sudo DEBIAN_FRONTEND=noninteractive apt install -y ./libwebkitgtk-1.0-0_2.4.11-3ubuntu3_amd64.deb
    
    log "Installing libcanberra-gtk-module..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y libcanberra-gtk-module
    
    log "Updating package cache..."
    sudo apt update
    
    success "All Pentaho dependencies installed successfully!"
}

# Verify installation
verify_installation() {
    header "Verifying Installation"
    
    log "Checking installed packages..."
    
    if dpkg-query -W -f='${Status}' libwebkitgtk-1.0-0 2>/dev/null | /bin/grep -q "install ok installed"; then
        success "libwebkitgtk-1.0-0 is installed"
    else
        error "libwebkitgtk-1.0-0 installation verification failed"
        return 1
    fi
    
    if dpkg-query -W -f='${Status}' libjavascriptcoregtk-1.0-0 2>/dev/null | /bin/grep -q "install ok installed"; then
        success "libjavascriptcoregtk-1.0-0 is installed"
    else
        error "libjavascriptcoregtk-1.0-0 installation verification failed"
        return 1
    fi
    
    echo ""
    log "Installed WebKit packages:"
    dpkg-query -l 'libwebkit*' 'libjavascriptcore*' 2>/dev/null || true
    echo ""
    
    success "Installation verified successfully!"
}

# Show usage
show_usage() {
    echo "Usage: $0 [-y|--yes]"
    echo ""
    echo "Installs legacy LibWebKitGTK 1.0 dependencies required for Pentaho UI components."
    echo ""
    echo "Options:"
    echo "  -y, --yes   Auto-confirm all prompts (no user interaction)"
    echo "  -h, --help  Show this help message"
    echo ""
    echo "Required packages location:"
    echo "  $PACKAGES_DIR"
}

# Main execution
main() {
    header "🎨 Pentaho Dependencies Installer"
    
    echo "This script will install legacy WebKitGTK 1.0 libraries required for:"
    echo "  • Pentaho Spoon (Data Integration)"
    echo "  • Pentaho Report Designer"
    echo "  • Pentaho Schema Workbench"
    echo "  • Other SWT-based Pentaho UI tools"
    echo ""
    
    if [[ "$AUTO_CONFIRM" == false ]]; then
        read -p "Do you want to continue? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation cancelled by user"
            exit 0
        fi
    else
        log "Auto-confirm enabled, proceeding with installation..."
    fi
    
    check_permissions
    check_packages
    
    # Check if already installed, skip if so (in auto mode)
    if ! check_existing_installation; then
        verify_installation  # Just verify what's already there
        header "✅ Already Installed"
        echo "Pentaho UI dependencies are already present on this system."
        echo ""
        return 0
    fi
    
    install_packages
    verify_installation
    
    header "✅ Installation Complete"
    echo "Pentaho UI components should now work correctly on this system."
    echo ""
}

# Handle command line arguments
case "${1:-}" in
    "-h"|"--help")
        show_usage
        exit 0
        ;;
    "-y"|"--yes")
        AUTO_CONFIRM=true
        main
        ;;
    "")
        main
        ;;
    *)
        error "Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
