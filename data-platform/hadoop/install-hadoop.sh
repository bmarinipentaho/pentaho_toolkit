#!/usr/bin/env bash
#
# Hadoop Installation Script
#
# Installs Apache Hadoop in pseudo-distributed mode for local development/testing.
# Supports version selection and checks for existing installations.

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

DEFAULT_HADOOP_VERSION="3.4.1"
HADOOP_VERSION="${HADOOP_VERSION:-$DEFAULT_HADOOP_VERSION}"
DATA_PLATFORM_BASE="${DATA_PLATFORM_BASE:-$HOME/data-platform}"
HADOOP_INSTALL_BASE="$DATA_PLATFORM_BASE/installs"
HADOOP_MIRROR="https://dlcdn.apache.org/hadoop/common"

# ============================================================================
# Functions
# ============================================================================

show_help() {
  cat << EOF
Hadoop Installation Script

USAGE:
  $(basename "$0") [OPTIONS]

OPTIONS:
  --version VERSION     Hadoop version to install (default: $DEFAULT_HADOOP_VERSION)
  --install-dir DIR     Custom installation base directory (default: $HADOOP_INSTALL_BASE)
  --force              Overwrite existing installation
  -h, --help           Show this help message

EXAMPLES:
  # Install default version (3.4.1)
  $(basename "$0")

  # Install specific version
  $(basename "$0") --version 3.3.6

  # Force reinstall
  $(basename "$0") --version 3.4.1 --force

INSTALLATION PATHS:
  Base directory:    $HADOOP_INSTALL_BASE
  Hadoop install:    $HADOOP_INSTALL_BASE/hadoop-{version}/
  Current symlink:   $HADOOP_INSTALL_BASE/hadoop-current -> hadoop-{version}
  
ENVIRONMENT VARIABLES:
  HADOOP_VERSION       Override default version (alternative to --version)
  DATA_PLATFORM_BASE   Change base installation directory

EOF
}

# Download Hadoop tarball
download_hadoop() {
  local version="$1"
  local dest_file="$2"
  
  local filename="hadoop-${version}.tar.gz"
  local url="$HADOOP_MIRROR/hadoop-${version}/${filename}"
  
  log "Downloading Hadoop $version"
  log "URL: $url"
  
  if ! curl -f -L --progress-bar -o "$dest_file" "$url"; then
    error "Download failed"
    log "Please verify:"
    log "  1. Version $version exists"
    log "  2. You have network access"
    log "  3. Mirror is available: $HADOOP_MIRROR"
    return 1
  fi
  
  success "Downloaded to $dest_file"
}

# Extract and setup Hadoop
install_hadoop_from_tarball() {
  local tarball="$1"
  local version="$2"
  local install_dir="$3"
  
  if [[ ! -f "$tarball" ]]; then
    die "Tarball not found: $tarball"
  fi
  
  log "Extracting Hadoop to $install_dir"
  
  # Create installation directory
  create_dir "$install_dir"
  
  # Extract tarball
  if ! tar -xzf "$tarball" -C "$install_dir" --strip-components=1; then
    die "Failed to extract tarball"
  fi
  
  success "Hadoop $version installed to $install_dir"
  
  # Show version info
  if [[ -f "$install_dir/bin/hadoop" ]]; then
    log "Hadoop version:"
    "$install_dir/bin/hadoop" version | head -1 | sed 's/^/  /' || true
  fi
}

# Create symlink to current installation
create_current_symlink() {
  local install_dir="$1"
  local symlink_path="$HADOOP_INSTALL_BASE/hadoop-current"
  
  if [[ -L "$symlink_path" ]]; then
    rm "$symlink_path"
  fi
  
  # Create relative symlink
  local relative_path
  relative_path=$(basename "$install_dir")
  
  (cd "$HADOOP_INSTALL_BASE" && ln -s "$relative_path" hadoop-current)
  success "Created symlink: hadoop-current -> $relative_path"
}

# ============================================================================
# Main Installation Logic
# ============================================================================

main() {
  local version="$HADOOP_VERSION"
  local install_base="$HADOOP_INSTALL_BASE"
  local force=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      --version)
        version="$2"
        shift 2
        ;;
      --install-dir)
        install_base="$2"
        shift 2
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
  
  header "Hadoop Installation"
  
  log "Version: $version"
  log "Installation base: $install_base"
  
  local install_dir="$install_base/hadoop-${version}"
  
  # Check for existing installation
  if [[ -d "$install_dir" ]]; then
    if [[ "$force" == true ]]; then
      warning "Removing existing installation: $install_dir"
      rm -rf "$install_dir"
    else
      die "Installation directory already exists: $install_dir (use --force to overwrite)"
    fi
  fi
  
  # Create base directory
  create_dir "$install_base"
  
  # Download Hadoop
  local temp_tarball
  temp_tarball=$(mktemp --suffix=.tar.gz)
  
  download_hadoop "$version" "$temp_tarball"
  install_hadoop_from_tarball "$temp_tarball" "$version" "$install_dir"
  
  rm "$temp_tarball"
  
  # Create symlink
  create_current_symlink "$install_dir"
  
  # Show installation summary
  separator
  success "Hadoop installation complete!"
  log ""
  log "Installation directory: $install_dir"
  log "Current symlink:        $install_base/hadoop-current"
  log ""
  log "Next steps:"
  log "  1. Configure Hadoop: ./data-platform/hadoop/configure-hadoop.sh"
  log "  2. Format HDFS: $install_base/hadoop-current/bin/hdfs namenode -format"
  log "  3. Start services: ./data-platform/hadoop/start-hadoop.sh"
  log ""
  log "Environment variable suggestions:"
  log "  export HADOOP_HOME=$install_dir"
  log "  export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin"
}

# Run main function
main "$@"
