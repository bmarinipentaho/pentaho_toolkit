#!/usr/bin/env bash
#
# PDI (Pentaho Data Integration) Installer
#
# Installation modes:
#   1. Local zip:        --zip-file /path/to/pdi.zip
#   2. Download build:   --version 11.0-QAT --build 203
#
# Features:
#   - Parallel installations supported (version/build/product structure)
#   - Automatic extraction and license installation
#   - Symbolic link to 'current' installation
#   - Integration with lib/common.sh

set -euo pipefail

# ============================================================================
# Path Resolution
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared libraries
# shellcheck source=../../lib/common.sh
if [[ -f "$TOOLKIT_ROOT/lib/common.sh" ]]; then
  source "$TOOLKIT_ROOT/lib/common.sh"
else
  echo "ERROR: Cannot find lib/common.sh at $TOOLKIT_ROOT/lib/common.sh" >&2
  exit 1
fi

# shellcheck source=../../lib/license-installer.sh
if [[ -f "$TOOLKIT_ROOT/lib/license-installer.sh" ]]; then
  source "$TOOLKIT_ROOT/lib/license-installer.sh"
else
  error "Cannot find lib/license-installer.sh"
  exit 1
fi

# ============================================================================
# Configuration
# ============================================================================

PENTAHO_BASE="${PENTAHO_BASE:-$HOME/pentaho}"
BUILD_SITE_URL="https://build.orl.eng.hitachivantara.com/hosted"
DEFAULT_VERSION="11.0-QAT"
DEFAULT_EDITION="ee"  # ce or ee

# ============================================================================
# Functions
# ============================================================================

show_help() {
  cat << EOF
PDI (Pentaho Data Integration) Installer

USAGE:
  $(basename "$0") [OPTIONS]

INSTALLATION MODES:
  --zip-file PATH           Install from local zip file
  --version VERSION         Specify PDI version (e.g., 11.0-QAT, 10.2.0.0)
  --build NUMBER            Specify build number
  --edition EDITION         Edition: ce or ee (default: ee)

OPTIONS:
  --license-url URL         Install license from flexnet URL
  --install-dir DIR         Custom installation directory (default: ~/pentaho/{version}/{build}/pdi)
  --no-symlink             Don't create 'current' symlink
  --force                  Overwrite existing installation
  -h, --help               Show this help message

EXAMPLES:
  # Install from local zip (recommended)
  $(basename "$0") --zip-file ~/downloads/pdi-ee-client-11.0.0.0-203.zip

  # Install with license
  $(basename "$0") --zip-file ~/downloads/pdi-ee-client-11.0.0.0-203.zip \\
    --license-url https://flex1826-uat.compliance.flexnetoperations.com/instances/YA6CTUK7XNAJ/request

  # Install from build site (requires correct URL pattern)
  $(basename "$0") --version 11.0-QAT --build 203

  # Install CE edition
  $(basename "$0") --version 11.0-QAT --build 203 --edition ce

NOTE:
  The build site uses JavaScript to load files dynamically and redirects
  to Artifactory. Direct downloads may not work as expected.
  Recommended approach: Download the zip manually, then use --zip-file.

INSTALLATION PATHS:
  Base directory:    $PENTAHO_BASE
  Version/build:     $PENTAHO_BASE/{version}/{build}/
  PDI install:       $PENTAHO_BASE/{version}/{build}/pdi/
  Current symlink:   $PENTAHO_BASE/current -> {version}/{build}

PARALLEL INSTALLATIONS:
  Multiple versions and builds can be installed simultaneously.
  All products for a version/build are grouped together.
  Use the version/build path or the 'current' symlink.

EOF
}

# Get download URL for specific version and build
get_download_url() {
  local version="$1"
  local build="$2"
  local edition="${3:-ee}"
  
  # Build filename based on observed pattern: pdi-ee-client-11.0.0.0-203.zip
  # Need to determine the full version number from the version folder name
  local filename
  
  # For QAT versions, need to map folder name to file version
  # 11.0-QAT folder contains pdi-ee-client-11.0.0.0-XXX.zip files
  local file_version="$version"
  if [[ "$version" == *"-QAT" ]]; then
    # Strip -QAT and add .0.0 suffix
    file_version="${version%-QAT}.0.0"
  elif [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    # If version is like "11.0", add .0.0
    file_version="${version}.0.0"
  fi
  
  filename="pdi-${edition}-client-${file_version}-${build}.zip"
  local url="$BUILD_SITE_URL/$version/$filename"
  
  echo "$url"
}

# Download PDI zip from build site
download_pdi() {
  local version="$1"
  local build="$2"
  local edition="$3"
  local dest_file="$4"
  
  local url
  url=$(get_download_url "$version" "$build" "$edition")
  
  log "Downloading PDI $version build $build ($edition)"
  log "URL: $url"
  
  if ! curl -f -L -o "$dest_file" "$url"; then
    error "Download failed"
    log "Please verify:"
    log "  1. Version and build number are correct"
    log "  2. You have network access to the build site"
    log "  3. The file exists at: $url"
    return 1
  fi
  
  success "Downloaded to $dest_file"
}

# Extract and setup PDI
install_pdi_from_zip() {
  local zip_file="$1"
  local install_dir="$2"
  
  if [[ ! -f "$zip_file" ]]; then
    die "Zip file not found: $zip_file"
  fi
  
  log "Extracting PDI to $install_dir"
  
  # Create installation directory
  create_dir "$install_dir"
  
  # Create project_profiles directory in pentaho base
  create_dir "$PENTAHO_BASE/project_profiles"
  
  # Extract entire zip file
  # PDI EE zips contain:
  #   - data-integration/    (main PDI installation)
  #   - license-installer/   (license installation tools)
  #   - jdbc-distribution/   (JDBC driver distribution tools)
  log "Extracting all contents from zip..."
  
  if ! unzip -q "$zip_file" -d "$install_dir"; then
    die "Failed to extract zip file"
  fi
  
  # Make all shell scripts executable
  find "$install_dir" -type f -name "*.sh" -exec chmod +x {} \;
  
  success "PDI installed to $install_dir"
  
  # Show what was extracted
  log "Extracted folders:"
  find "$install_dir" -maxdepth 1 -type d -not -path "$install_dir" -exec basename {} \; | sed 's/^/  - /' || true
  
  # Show version info if available
  if [[ -f "$install_dir/data-integration/version.xml" ]]; then
    log "Version information:"
    grep -E "<version>|<buildNumber>" "$install_dir/data-integration/version.xml" | sed 's/^/  /' || true
  fi
}

# Install license using shared library
install_license() {
  local install_dir="$1"
  local license_url="$2"
  
  install_pentaho_license "$install_dir" "$license_url"
}

# Create symlink to current installation
create_current_symlink() {
  local install_dir="$1"
  local symlink_path="$PENTAHO_BASE/current"
  
  # install_dir is ~/pentaho/{version}/{build}/pdi
  # We want symlink to point to ~/pentaho/{version}/{build}
  local build_dir
  build_dir=$(dirname "$install_dir")
  
  if [[ -L "$symlink_path" ]]; then
    rm "$symlink_path"
  fi
  
  # Create relative symlink from base to version/build
  local relative_path
  relative_path=$(realpath --relative-to="$PENTAHO_BASE" "$build_dir")
  
  (cd "$PENTAHO_BASE" && ln -s "$relative_path" current)
  success "Created symlink: current -> $relative_path"
}

# ============================================================================
# Main Installation Logic
# ============================================================================

main() {
  local zip_file=""
  local version="$DEFAULT_VERSION"
  local build=""
  local edition="$DEFAULT_EDITION"
  local install_dir=""
  local license_url=""
  local create_symlink=true
  local force=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      --zip-file)
        zip_file="$2"
        shift 2
        ;;
      --version)
        version="$2"
        shift 2
        ;;
      --build)
        build="$2"
        shift 2
        ;;
      --edition)
        edition="$2"
        shift 2
        ;;
      --license-url)
        license_url="$2"
        shift 2
        ;;
      --install-dir)
        install_dir="$2"
        shift 2
        ;;
      --no-symlink)
        create_symlink=false
        shift
        ;;
      --force)
        force=true
        shift
        ;;
      *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  
  # Validate edition
  if [[ "$edition" != "ce" ]] && [[ "$edition" != "ee" ]]; then
    die "Edition must be 'ce' or 'ee', got: $edition"
  fi
  
  # Determine installation mode
  local mode=""
  if [[ -n "$zip_file" ]]; then
    mode="local"
  elif [[ -n "$version" ]] && [[ -n "$build" ]]; then
    mode="download"
  else
    error "Installation mode required"
    log "Use either:"
    log "  --zip-file PATH"
    log "  --version VERSION --build NUMBER"
    show_help
    exit 1
  fi
  
  header "PDI Installation"
  
  # Execute installation based on mode
  case $mode in
    local)
      log "Mode: Local zip file"
      log "File: $zip_file"
      
      # Extract edition and build from filename if possible
      # Pattern: pdi-ee-client-11.0.0.0-203.zip or pdi-ce-client-10.2.0.0-999.zip
      # Note: We extract the build number but keep the version as-is (e.g., 11.0-QAT)
      local file_version=""
      if [[ "$zip_file" =~ pdi-(ce|ee)-client-([0-9.]+)-([0-9]+) ]]; then
        edition="${BASH_REMATCH[1]}"
        file_version="${BASH_REMATCH[2]}"
        build="${BASH_REMATCH[3]}"
        log "Detected edition: $edition, file version: $file_version, build: $build"
        
        # If version wasn't explicitly provided, use the default
        if [[ "$version" == "$DEFAULT_VERSION" ]]; then
          log "Using version: $version (override with --version if different)"
        fi
      else
        warning "Could not detect version/build from filename"
        if [[ "$version" == "$DEFAULT_VERSION" ]]; then
          version="unknown"
        fi
        build=$(date +%s)
      fi
      
      if [[ -z "$install_dir" ]]; then
        install_dir="$PENTAHO_BASE/${version}/${build}/pdi"
      fi
      
      if [[ -d "$install_dir" ]]; then
        if [[ "$force" == true ]]; then
          warning "Removing existing installation: $install_dir"
          rm -rf "$install_dir"
        else
          die "Installation directory already exists: $install_dir (use --force to overwrite)"
        fi
      fi
      
      install_pdi_from_zip "$zip_file" "$install_dir"
      
      # Install license if URL provided
      if [[ -n "$license_url" ]]; then
        install_license "$install_dir" "$license_url"
      fi
      ;;
      
    download)
      log "Mode: Download specific build"
      log "Version: $version"
      log "Build: $build"
      log "Edition: $edition"
      
      if [[ -z "$install_dir" ]]; then
        install_dir="$PENTAHO_BASE/${version}/${build}/pdi"
      fi
      
      if [[ -d "$install_dir" ]]; then
        if [[ "$force" == true ]]; then
          warning "Removing existing installation: $install_dir"
          rm -rf "$install_dir"
        else
          die "Installation directory already exists: $install_dir (use --force to overwrite)"
        fi
      fi
      
      local temp_zip
      temp_zip=$(mktemp --suffix=.zip)
      
      download_pdi "$version" "$build" "$edition" "$temp_zip"
      install_pdi_from_zip "$temp_zip" "$install_dir"
      
      # Install license if URL provided
      if [[ -n "$license_url" ]]; then
        install_license "$install_dir" "$license_url"
      fi
      
      rm "$temp_zip"
      ;;
  esac
  
  # Create symlink if requested
  if [[ "$create_symlink" == true ]]; then
    create_current_symlink "$install_dir"
  fi
  
  # Show installation summary
  separator
  success "PDI installation complete!"
  log ""
  log "Installation directory: $install_dir"
  if [[ "$create_symlink" == true ]]; then
    log "Current symlink:        $PENTAHO_BASE/current"
  fi
  log ""
  log "To use PDI:"
  log "  cd $install_dir/data-integration"
  log "  ./spoon.sh              # Start Spoon (GUI)"
  log "  ./kitchen.sh --help     # Run jobs"
  log "  ./pan.sh --help         # Run transformations"
  log ""
  log "Environment variable suggestions:"
  log "  export PDI_HOME=$install_dir/data-integration"
  log "  export PATH=\$PATH:\$PDI_HOME"
}

# Run main function
main "$@"
