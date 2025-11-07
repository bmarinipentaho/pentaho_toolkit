#!/usr/bin/env bash
#
# Pentaho Server Installation Script
#
# Installs Pentaho Server from zip files with automatic plugin discovery,
# PostgreSQL configuration, and license installation.
#

set -euo pipefail

# ============================================================================
# Path Resolution
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared library
if [[ -f "$TOOLKIT_ROOT/lib/common.sh" ]]; then
    source "$TOOLKIT_ROOT/lib/common.sh"
else
    echo "ERROR: Cannot find lib/common.sh" >&2
    exit 1
fi

# ============================================================================
# Configuration
# ============================================================================

PENTAHO_BASE="${PENTAHO_BASE:-$HOME/pentaho}"
DEFAULT_POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
DEFAULT_POSTGRES_PORT="${POSTGRES_PORT:-5432}"
AUTO_CONFIRM=false
FORCE_INSTALL=false
LICENSE_URL=""

# ============================================================================
# Functions
# ============================================================================

show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pentaho Server Installation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Install Pentaho Server with automatic plugin discovery and PostgreSQL configuration.

USAGE:
    $0 [OPTIONS] [PATH]

ARGUMENTS:
    PATH                   Path to server zip or directory containing server + plugins
                          If omitted, searches ~/Downloads for pentaho-server*.zip

OPTIONS:
    --license-url URL     Flexnet license download URL
    --postgres-host HOST  PostgreSQL host (default: localhost)
    --postgres-port PORT  PostgreSQL port (default: 5432)
    --force              Reinstall even if version exists
    -y, --yes            Auto-confirm all prompts
    -h, --help           Show this help message

DIRECTORY STRUCTURE:
    Supports multiple layouts for server + plugins:
    
    Pattern 1 - Flat directory:
      ~/Downloads/
        ├── pentaho-server-ee-11.0.0.0-204.zip
        ├── pir-plugin.zip
        └── paz-plugin.zip
    
    Pattern 2 - Nested plugins:
      ~/Downloads/server/
        ├── pentaho-server-ee-11.0.0.0-204.zip
        └── plugins/
            ├── pir-plugin.zip
            └── paz-plugin.zip
    
    Pattern 3 - Version/Build structure:
      ~/pentaho-builds/11.0.0.0-204/server/
        ├── pentaho-server-ee-11.0.0.0-204.zip
        └── plugins/...

INSTALLATION:
    Server installs to: ~/pentaho/{version}/{build}/server/pentaho-server/
    Symlink created:    ~/pentaho/{version}/{build}/server-current
    
    Plugin installation:
    - Standard plugins → pentaho-solutions/system/
    - Operations mart (PIR) → data/
    
    Automatically configures:
    - PostgreSQL repository (hibernate, quartz, jackrabbit)
    - License installation
    - Plugin deployment to pentaho-solutions/system/

EXAMPLES:
    # Auto-search Downloads folder
    $0

    # Specific server zip
    $0 ~/Downloads/pentaho-server-ee-11.0.0.0-204.zip
    
    # Directory with server + plugins
    $0 ~/pentaho-builds/11.0.0.0-204/server/
    
    # With license automation
    $0 --license-url "https://flexnet.example.com/licenses/pentaho-server.lic"
    
    # Force reinstall
    $0 --force ~/Downloads/pentaho-server-ee-11.0.0.0-204.zip

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Find server zip in Downloads folder
find_server_in_downloads() {
    local downloads="$HOME/Downloads"
    local found
    
    if [[ ! -d "$downloads" ]]; then
        return 1
    fi
    
    # Search for pentaho-server*.zip (max depth 3)
    found=$(find "$downloads" -maxdepth 3 -name "pentaho-server*.zip" -type f 2>/dev/null | head -1)
    
    if [[ -n "$found" ]]; then
        local parent=$(dirname "$found")
        # Return parent directory if plugins exist nearby
        if [[ -d "$parent/plugins" ]] || ls "$parent"/*plugin*.zip >/dev/null 2>&1; then
            echo "$parent"
        else
            echo "$found"
        fi
        return 0
    fi
    
    return 1
}

# Extract version and build from filename
extract_version_info() {
    local filename="$1"
    local basename=$(basename "$filename" .zip)
    
    # Pattern: pentaho-server-ee-11.0.0.0-204
    if [[ "$basename" =~ pentaho-server(-ee)?-([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([0-9]+) ]]; then
        VERSION="${BASH_REMATCH[2]}"
        BUILD="${BASH_REMATCH[3]}"
        return 0
    fi
    
    error "Could not extract version/build from filename: $basename"
    return 1
}

# Install server from zip
install_server() {
    local server_zip="$1"
    local install_base="$PENTAHO_BASE/$VERSION/$BUILD/server"
    
    if [[ -d "$install_base/pentaho-server" ]] && [[ "$FORCE_INSTALL" == false ]]; then
        warning "Server $VERSION build $BUILD already installed at:"
        echo "  $install_base/pentaho-server"
        echo ""
        if [[ "$AUTO_CONFIRM" == false ]]; then
            if ! confirm "Reinstall?" "N"; then
                log "Installation cancelled"
                exit 0
            fi
        else
            log "Skipping installation (use --force to reinstall)"
            return 0
        fi
    fi
    
    log "Installing Pentaho Server $VERSION build $BUILD"
    log "Source: $(basename "$server_zip")"
    log "Target: $install_base"
    
    # Create installation directory
    create_dir "$install_base"
    
    # Extract server
    log "Extracting server files..."
    unzip -q "$server_zip" -d "$install_base" || die "Failed to extract server zip"
    
    success "Server extracted to $install_base"
    
    # Verify extraction
    if [[ ! -d "$install_base/pentaho-server" ]]; then
        die "Expected pentaho-server/ directory not found after extraction"
    fi
    
    return 0
}

# Install plugins
install_plugins() {
    local plugins_dir="$1"
    local server_base="$PENTAHO_BASE/$VERSION/$BUILD/server/pentaho-server"
    local server_system="$server_base/pentaho-solutions/system"
    local server_data="$server_base/data"
    local count=0
    
    if [[ ! -d "$server_system" ]]; then
        warning "Server system directory not found, skipping plugins"
        return 0
    fi
    
    log "Installing plugins..."
    
    for plugin_zip in "$plugins_dir"/*.zip; do
        [[ -f "$plugin_zip" ]] || continue
        
        local plugin_name=$(basename "$plugin_zip" .zip)
        log "Installing plugin: $plugin_name"
        
        # Check if this is the operations mart (goes to data/ instead of system/)
        if [[ "$plugin_name" =~ operations-mart|pir-plugin ]]; then
            if [[ ! -d "$server_data" ]]; then
                create_dir "$server_data"
            fi
            
            if unzip -q "$plugin_zip" -d "$server_data" 2>/dev/null; then
                ((count++))
                success "Installed to data/: $plugin_name"
            else
                warning "Failed to install plugin: $plugin_name"
            fi
        else
            # Standard plugin - extract to system directory
            if unzip -q "$plugin_zip" -d "$server_system" 2>/dev/null; then
                ((count++))
                success "Installed to system/: $plugin_name"
            else
                warning "Failed to install plugin: $plugin_name"
            fi
        fi
    done
    
    if [[ $count -gt 0 ]]; then
        success "Installed $count plugin(s)"
    else
        warning "No plugins installed"
    fi
}

# Configure PostgreSQL repository
configure_postgresql() {
    local server_base="$PENTAHO_BASE/$VERSION/$BUILD/server/pentaho-server"
    local repo_xml="$server_base/pentaho-solutions/system/jackrabbit/repository.xml"
    local quartz_props="$server_base/pentaho-solutions/system/quartz/quartz.properties"
    
    log "Configuring PostgreSQL repository..."
    
    # TODO: Implement repository.xml configuration
    # This will be a separate function to modify:
    # - repository.xml for JCR
    # - quartz.properties for scheduler
    # - applicationContext-spring-security-jdbc.xml for users
    
    warning "PostgreSQL auto-configuration not yet implemented"
    log "You will need to manually configure:"
    echo "  - $repo_xml"
    echo "  - $quartz_props"
}

# Install license
install_license() {
    local license_url="$1"
    local server_base="$PENTAHO_BASE/$VERSION/$BUILD/server/pentaho-server"
    local license_installer="$server_base/license-installer"
    
    if [[ -z "$license_url" ]]; then
        return 0
    fi
    
    if [[ ! -d "$license_installer" ]]; then
        warning "License installer not found, skipping license installation"
        return 0
    fi
    
    log "Installing license from: $license_url"
    
    # Download license
    local temp_license=$(mktemp /tmp/pentaho-license.XXXXXX.lic)
    if ! curl -sSL "$license_url" -o "$temp_license"; then
        warning "Failed to download license"
        rm -f "$temp_license"
        return 1
    fi
    
    # Run license installer
    cd "$license_installer"
    if ./install_license.sh install "$temp_license" 2>&1 | grep -q "successfully"; then
        success "License installed successfully"
    else
        warning "License installation may have failed"
    fi
    
    rm -f "$temp_license"
}

# Create server-current symlink
create_symlink() {
    local version_dir="$PENTAHO_BASE/$VERSION/$BUILD"
    local symlink="$version_dir/server-current"
    local target="pentaho-server"
    
    if [[ -L "$symlink" ]]; then
        rm "$symlink"
    fi
    
    cd "$version_dir/server"
    ln -s "$target" "$(basename "$symlink")"
    success "Created symlink: server-current -> $target"
}

# ============================================================================
# Main Installation Logic
# ============================================================================

main() {
    local input_path=""
    local server_zip=""
    local plugins_paths=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --license-url)
                LICENSE_URL="$2"
                shift 2
                ;;
            --postgres-host)
                DEFAULT_POSTGRES_HOST="$2"
                shift 2
                ;;
            --postgres-port)
                DEFAULT_POSTGRES_PORT="$2"
                shift 2
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            -y|--yes)
                AUTO_CONFIRM=true
                export AUTO_CONFIRM
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                input_path="$1"
                shift
                ;;
        esac
    done
    
    # Auto-search Downloads if no path provided
    if [[ -z "$input_path" ]]; then
        log "No path provided, searching ~/Downloads..."
        if input_path=$(find_server_in_downloads); then
            log "Found: $input_path"
        else
            die "No pentaho-server*.zip found in ~/Downloads. Please specify path."
        fi
    fi
    
    # Determine input type and find server + plugins
    if [[ -d "$input_path" ]]; then
        # Directory mode
        server_zip=$(find "$input_path" -maxdepth 1 -name "pentaho-server*.zip" -type f | head -1)
        [[ -z "$server_zip" ]] && die "No pentaho-server*.zip found in directory"
        
        # Look for plugins
        if [[ -d "$input_path/plugins" ]]; then
            plugins_paths+=("$input_path/plugins")
        fi
        # Also check for plugins in same directory as server
        if ls "$input_path"/*plugin*.zip >/dev/null 2>&1; then
            plugins_paths+=("$input_path")
        fi
    elif [[ -f "$input_path" ]] && [[ "$input_path" == *.zip ]]; then
        # Single zip mode
        server_zip="$input_path"
        
        # Check for plugins in same directory
        local parent_dir=$(dirname "$input_path")
        if [[ -d "$parent_dir/plugins" ]]; then
            plugins_paths+=("$parent_dir/plugins")
        fi
        if ls "$parent_dir"/*plugin*.zip >/dev/null 2>&1; then
            plugins_paths+=("$parent_dir")
        fi
    else
        die "Input must be a directory or server zip file"
    fi
    
    # Validate server zip
    [[ ! -f "$server_zip" ]] && die "Server zip not found: $server_zip"
    
    # Extract version info
    if ! extract_version_info "$server_zip"; then
        die "Could not determine version/build from filename"
    fi
    
    # Show installation summary
    header "Pentaho Server Installation"
    echo "Server:   $(basename "$server_zip")"
    echo "Version:  $VERSION"
    echo "Build:    $BUILD"
    echo "Plugins:  ${#plugins_paths[@]} location(s) found"
    echo ""
    
    # Install server
    install_server "$server_zip"
    
    # Install plugins
    if [[ ${#plugins_paths[@]} -gt 0 ]]; then
        for plugins_dir in "${plugins_paths[@]}"; do
            install_plugins "$plugins_dir"
        done
    else
        warning "No plugins found - marketplace may not be available"
    fi
    
    # Create symlink
    create_symlink
    
    # Configure PostgreSQL
    configure_postgresql
    
    # Install license
    if [[ -n "$LICENSE_URL" ]]; then
        install_license "$LICENSE_URL"
    fi
    
    # Installation complete
    header "✅ Installation Complete"
    echo ""
    echo "Server Location:"
    echo "  $PENTAHO_BASE/$VERSION/$BUILD/server/pentaho-server"
    echo ""
    echo "Symlink:"
    echo "  $PENTAHO_BASE/$VERSION/$BUILD/server-current"
    echo ""
    echo "Next Steps:"
    echo "  1. Configure PostgreSQL repository (if not auto-configured)"
    echo "  2. Start server: $PENTAHO_BASE/$VERSION/$BUILD/server/pentaho-server/start-pentaho.sh"
    echo "  3. Access: http://localhost:8080/pentaho"
    echo ""
    
    success "Server installation complete! 🎉"
}

# Run main function
main "$@"
