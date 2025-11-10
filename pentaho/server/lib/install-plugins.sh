#!/usr/bin/env bash
#
# Pentaho Server Plugin Installation Library
#
# Handles plugin discovery, validation, and installation.
#

# ============================================================================
# Plugin Configuration
# ============================================================================

# Whitelist of known valid plugin patterns
declare -g -a KNOWN_PLUGINS=(
    "paz-plugin"           # Pentaho Analyzer
    "pir-plugin"           # Pentaho Interactive Reporting (Operations Mart)
    "operations-mart"      # Operations Mart (alternative name)
    "pdd-plugin"           # Pentaho Data Access
)

# ============================================================================
# Functions
# ============================================================================

# Validate plugin against whitelist
is_valid_plugin() {
    local plugin_name="$1"
    
    # Skip if this is the server zip itself
    if [[ "$plugin_name" =~ pentaho-server ]]; then
        return 1
    fi
    
    # Check if plugin matches whitelist
    for known_plugin in "${KNOWN_PLUGINS[@]}"; do
        if [[ "$plugin_name" =~ $known_plugin ]]; then
            return 0
        fi
    done
    
    return 1
}

# Extract version info from plugin filename
get_plugin_version() {
    local plugin_name="$1"
    
    if [[ "$plugin_name" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    return 1
}

# Extract build from plugin filename
get_plugin_build() {
    local plugin_name="$1"
    
    if [[ "$plugin_name" =~ ([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)-([0-9]+) ]]; then
        echo "${BASH_REMATCH[2]}"
        return 0
    fi
    
    return 1
}

# Determine if plugin goes to data/ directory
is_data_plugin() {
    local plugin_name="$1"
    [[ "$plugin_name" =~ operations-mart|pir-plugin ]]
}

# Install a single plugin
install_plugin() {
    local plugin_zip="$1"
    local server_base="$2"
    local server_version="$3"
    local server_build="$4"
    
    local plugin_name
    plugin_name=$(basename "$plugin_zip" .zip)
    local server_system="$server_base/pentaho-solutions/system"
    local server_data="$server_base/data"
    
    # Validate plugin
    if ! is_valid_plugin "$plugin_name"; then
        log "Skipping unknown file: $plugin_name (not a recognized plugin)"
        return 2  # Skip code
    fi
    
    # Verify file is readable
    if [[ ! -r "$plugin_zip" ]]; then
        error "Cannot read plugin file: $plugin_zip"
        warning "Skipping plugin: $plugin_name"
        return 2  # Skip code
    fi
    
    # Extract and validate version
    local plugin_version plugin_build
    if plugin_version=$(get_plugin_version "$plugin_name") && \
       plugin_build=$(get_plugin_build "$plugin_name"); then
        
        # Validate version/build match
        # Extract major.minor from both (e.g., 11.0 from 11.0.0.0 or 11.0-QAT)
        local server_major_minor="${server_version%%-*}"  # Strip -QAT suffix
        server_major_minor="${server_major_minor%%.*}.${server_major_minor#*.}"  # Get X.Y
        server_major_minor="${server_major_minor%%.*}"  # Keep only first two parts
        
        local plugin_major_minor="${plugin_version%%.*}.${plugin_version#*.}"
        plugin_major_minor="${plugin_major_minor%%.*}"
        
        # Check build number matches
        if [[ "$plugin_build" != "$server_build" ]]; then
            error "Build mismatch: $plugin_name (build $plugin_build) != Server (build $server_build)"
            warning "Skipping incompatible plugin: $plugin_name"
            return 2  # Skip code
        fi
        
        log "Version check: plugin=$plugin_version (build $plugin_build), server=$server_version (build $server_build)"
    else
        warning "No version found in plugin filename: $plugin_name (installing anyway)"
    fi
    
    log "Installing plugin: $plugin_name"
    
    # Determine installation directory
    if is_data_plugin "$plugin_name"; then
        if [[ ! -d "$server_data" ]]; then
            mkdir -p "$server_data" || {
                error "Failed to create data directory"
                return 1
            }
        fi
        
        log "Extracting to data/..."
        if (unzip -qo "$plugin_zip" -d "$server_data" < /dev/null); then
            success "Installed to data/: $plugin_name"
            return 0
        else
            warning "Failed to extract plugin: $plugin_name"
            return 1
        fi
    else
        log "Extracting to system/..."
        if (unzip -qo "$plugin_zip" -d "$server_system" < /dev/null); then
            success "Installed to system/: $plugin_name"
            return 0
        else
            warning "Failed to extract plugin: $plugin_name"
            return 1
        fi
    fi
}

# Install all plugins from directory
install_plugins_from_directory() {
    local plugins_dir="$1"
    local server_base="$2"
    local server_version="$3"
    local server_build="$4"
    
    local count=0
    local skipped=0
    local failed=0
    
    log "Installing plugins for server version $server_version build $server_build..."
    
    for plugin_zip in "$plugins_dir"/*.zip; do
        [[ -f "$plugin_zip" ]] || continue
        
        set +e
        install_plugin "$plugin_zip" "$server_base" "$server_version" "$server_build"
        local result=$?
        set -e
        
        case $result in
            0)
                count=$((count + 1))
                ;;
            1)
                failed=$((failed + 1))
                ;;
            2)
                skipped=$((skipped + 1))
                ;;
        esac
    done
    
    # Summary
    if [[ $count -gt 0 ]]; then
        success "Installed $count plugin(s)"
    else
        warning "No plugins installed"
    fi
    
    if [[ $skipped -gt 0 ]]; then
        warning "Skipped $skipped incompatible plugin(s)"
    fi
    
    if [[ $failed -gt 0 ]]; then
        warning "Failed to install $failed plugin(s)"
    fi
    
    return 0
}
