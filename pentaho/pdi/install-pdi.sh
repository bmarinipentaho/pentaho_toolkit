#!/usr/bin/env bash
#
# PDI (Pentaho Data Integration) Installer
#
# Installation modes:
#   1. Local zip:        --zip-file /path/to/pdi.zip
#   2. Version + build:  --version 10.2.0.0 --build 999
#   3. Version + latest: --version 10.2.0.0 --latest
#   4. List builds:      --list-builds --version 10.2.0.0
#
# Features:
#   - Parallel installations supported (version-based paths)
#   - Automatic extraction and setup
#   - Symbolic link to 'current' installation
#   - Integration with lib/common.sh

set -euo pipefail

# ============================================================================
# Path Resolution
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared library
# shellcheck source=../../lib/common.sh
if [[ -f "$TOOLKIT_ROOT/lib/common.sh" ]]; then
  source "$TOOLKIT_ROOT/lib/common.sh"
else
  echo "ERROR: Cannot find lib/common.sh at $TOOLKIT_ROOT/lib/common.sh" >&2
  exit 1
fi

# ============================================================================
# Configuration
# ============================================================================

PDI_INSTALL_BASE="${PDI_INSTALL_BASE:-$HOME/pentaho/pdi}"
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
  --install-dir DIR         Custom installation directory (default: ~/pentaho/pdi)
  --no-symlink             Don't create 'current' symlink
  --force                  Overwrite existing installation
  -h, --help               Show this help message

EXAMPLES:
  # Install from local zip (recommended)
  $(basename "$0") --zip-file ~/downloads/pdi-ee-client-11.0.0.0-203.zip

  # Install from build site (requires correct URL pattern)
  $(basename "$0") --version 11.0-QAT --build 203

  # Install CE edition
  $(basename "$0") --version 11.0-QAT --build 203 --edition ce

NOTE:
  The build site uses JavaScript to load files dynamically and redirects
  to Artifactory. Direct downloads may not work as expected.
  Recommended approach: Download the zip manually, then use --zip-file.

INSTALLATION PATHS:
  Base directory:    $PDI_INSTALL_BASE
  Version install:   $PDI_INSTALL_BASE/{version}-{build}
  Current symlink:   $PDI_INSTALL_BASE/current -> {version}-{build}

PARALLEL INSTALLATIONS:
  Multiple PDI versions can be installed simultaneously.
  Use the version-build path or the 'current' symlink.

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
  
  # Extract zip
  # PDI zips typically extract to a 'data-integration' folder
  local temp_dir
  temp_dir=$(mktemp -d)
  
  if ! unzip -q "$zip_file" -d "$temp_dir"; then
    rm -rf "$temp_dir"
    die "Failed to extract zip file"
  fi
  
  # Move contents from data-integration folder to install_dir
  if [[ -d "$temp_dir/data-integration" ]]; then
    mv "$temp_dir/data-integration"/* "$install_dir/"
    rm -rf "$temp_dir"
  else
    # If no data-integration folder, move everything
    mv "$temp_dir"/* "$install_dir/"
    rm -rf "$temp_dir"
  fi
  
  # Make scripts executable
  chmod +x "$install_dir"/*.sh 2>/dev/null || true
  
  success "PDI installed to $install_dir"
  
  # Show version info if available
  if [[ -f "$install_dir/version.xml" ]]; then
    log "Version information:"
    grep -E "<version>|<buildNumber>" "$install_dir/version.xml" | sed 's/^/  /' || true
  fi
}

# Create symlink to current installation
create_current_symlink() {
  local install_dir="$1"
  local symlink_path="$PDI_INSTALL_BASE/current"
  
  if [[ -L "$symlink_path" ]]; then
    rm "$symlink_path"
  fi
  
  ln -s "$install_dir" "$symlink_path"
  success "Created symlink: current -> $(basename "$install_dir")"
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
      
      # Extract version and build from filename if possible
      # Pattern: pdi-ee-client-11.0.0.0-203.zip or pdi-ce-client-10.2.0.0-999.zip
      if [[ "$zip_file" =~ pdi-(ce|ee)-client-([0-9.]+)-([0-9]+) ]]; then
        edition="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        build="${BASH_REMATCH[3]}"
        log "Detected edition: $edition, version: $version, build: $build"
      else
        warning "Could not detect version/build from filename"
        version="unknown"
        build=$(date +%s)
      fi
      
      if [[ -z "$install_dir" ]]; then
        install_dir="$PDI_INSTALL_BASE/${version}-${build}"
      fi
      
      if [[ -d "$install_dir" ]] && [[ "$force" != true ]]; then
        die "Installation directory already exists: $install_dir (use --force to overwrite)"
      fi
      
      install_pdi_from_zip "$zip_file" "$install_dir"
      ;;
      
    download)
      log "Mode: Download specific build"
      log "Version: $version"
      log "Build: $build"
      log "Edition: $edition"
      
      if [[ -z "$install_dir" ]]; then
        install_dir="$PDI_INSTALL_BASE/${version}-${build}"
      fi
      
      if [[ -d "$install_dir" ]] && [[ "$force" != true ]]; then
        die "Installation directory already exists: $install_dir (use --force to overwrite)"
      fi
      
      local temp_zip
      temp_zip=$(mktemp --suffix=.zip)
      
      download_pdi "$version" "$build" "$edition" "$temp_zip"
      install_pdi_from_zip "$temp_zip" "$install_dir"
      
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
    log "Current symlink:        $PDI_INSTALL_BASE/current"
  fi
  log ""
  log "To use PDI:"
  log "  cd $install_dir"
  log "  ./spoon.sh              # Start Spoon (GUI)"
  log "  ./kitchen.sh --help     # Run jobs"
  log "  ./pan.sh --help         # Run transformations"
  log ""
  log "Environment variable suggestions:"
  log "  export PDI_HOME=$install_dir"
  log "  export PATH=\$PATH:\$PDI_HOME"
}

# Run main function
main "$@"
