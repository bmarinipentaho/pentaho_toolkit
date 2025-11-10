#!/usr/bin/env bash
#
# Shared License Installation Library
#
# Handles license installation for both PDI and Server using flexnet URLs.
#

# Install license from flexnet URL
# Args: $1 = installation directory (containing license-installer/)
#       $2 = license URL
install_pentaho_license() {
    local install_dir="$1"
    local license_url="$2"
    
    local license_installer="$install_dir/license-installer"
    local license_script="$license_installer/install_license.sh"
    
    # Validate inputs
    if [[ -z "$install_dir" ]] || [[ -z "$license_url" ]]; then
        error "install_pentaho_license requires install_dir and license_url"
        return 1
    fi
    
    # Check if license installer exists
    if [[ ! -d "$license_installer" ]]; then
        warning "License installer directory not found: $license_installer"
        return 1
    fi
    
    if [[ ! -f "$license_script" ]]; then
        warning "License installer script not found: $license_script"
        return 1
    fi
    
    log "Installing license from flexnet..."
    log "Source: $license_url"
    
    # Try direct URL method (PDI style - preferred)
    if (cd "$license_installer" && ./install_license.sh "$license_url" 2>&1); then
        success "License installed successfully"
        return 0
    fi
    
    # Fallback: Download and install (Server style)
    log "Trying alternative installation method..."
    local temp_license
    temp_license=$(mktemp /tmp/pentaho-license.XXXXXX.lic)
    
    if ! curl -sSL "$license_url" -o "$temp_license"; then
        error "Failed to download license from URL"
        rm -f "$temp_license"
        return 1
    fi
    
    # Try install with downloaded file
    if (cd "$license_installer" && ./install_license.sh install "$temp_license" 2>&1 | grep -q "successfully"); then
        rm -f "$temp_license"
        success "License installed successfully"
        return 0
    else
        rm -f "$temp_license"
        error "License installation failed"
        return 1
    fi
}

# Check if license is already installed
# Args: $1 = installation directory
check_license_installed() {
    local install_dir="$1"
    local license_file="$install_dir/.installedLicenses.xml"
    
    if [[ -f "$license_file" ]]; then
        return 0
    fi
    
    return 1
}

# Show license information if installed
# Args: $1 = installation directory
show_license_info() {
    local install_dir="$1"
    local license_file="$install_dir/.installedLicenses.xml"
    
    if [[ -f "$license_file" ]]; then
        log "License information:"
        # Extract basic info if xmlstarlet is available
        if command -v xmlstarlet &>/dev/null; then
            xmlstarlet sel -t -v "//license/@product" -n "$license_file" 2>/dev/null || \
                log "  (License file exists but cannot parse)"
        else
            log "  License installed (use xmlstarlet to view details)"
        fi
    else
        warning "No license installed"
    fi
}
