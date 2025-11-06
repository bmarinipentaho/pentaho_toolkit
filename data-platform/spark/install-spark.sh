#!/usr/bin/env bash
#
# Spark Installation Script
#
# Installs Apache Spark for local development/testing with Hadoop integration.
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

DEFAULT_SPARK_VERSION="4.0.0"
SPARK_VERSION="${SPARK_VERSION:-$DEFAULT_SPARK_VERSION}"
DATA_PLATFORM_BASE="${DATA_PLATFORM_BASE:-$HOME/data-platform}"
SPARK_INSTALL_BASE="$DATA_PLATFORM_BASE/installs"
SPARK_MIRROR="https://archive.apache.org/dist/spark"

# ============================================================================
# Functions
# ============================================================================

show_help() {
  cat << EOF
Spark Installation Script

USAGE:
  $(basename "$0") [OPTIONS]

OPTIONS:
  --version VERSION     Spark version to install (default: $DEFAULT_SPARK_VERSION)
  --hadoop-version VER  Hadoop version for pre-built package (default: hadoop3)
  --install-dir DIR     Custom installation base directory (default: $SPARK_INSTALL_BASE)
  --force              Overwrite existing installation
  -h, --help           Show this help message

EXAMPLES:
  # Install default version (4.0.0)
  $(basename "$0")

  # Install specific version
  $(basename "$0") --version 3.5.3

  # Install with specific Hadoop compatibility
  $(basename "$0") --version 4.0.0 --hadoop-version hadoop3

  # Force reinstall
  $(basename "$0") --version 4.0.0 --force

INSTALLATION PATHS:
  Base directory:    $SPARK_INSTALL_BASE
  Spark install:     $SPARK_INSTALL_BASE/spark-{version}/
  Current symlink:   $SPARK_INSTALL_BASE/spark-current -> spark-{version}
  
ENVIRONMENT VARIABLES:
  SPARK_VERSION        Override default version (alternative to --version)
  DATA_PLATFORM_BASE   Change base installation directory

NOTE:
  This script downloads pre-built Spark packages with Hadoop libraries included.
  Ensure the Hadoop version matches your local Hadoop installation.

EOF
}

# Download Spark tarball
download_spark() {
  local version="$1"
  local hadoop_version="$2"
  local dest_file="$3"
  
  # Determine filename pattern based on Spark version
  # Spark 4.0.0+ uses: spark-4.0.0-bin-hadoop3-connect.tgz
  # Spark 3.x uses: spark-3.5.4-bin-hadoop3.tgz
  local filename
  local version_major
  version_major=$(echo "$version" | cut -d. -f1)
  
  if [[ "$version_major" -ge 4 ]]; then
    # Spark 4.x naming pattern
    filename="spark-${version}-bin-${hadoop_version}-connect.tgz"
  else
    # Spark 3.x naming pattern
    filename="spark-${version}-bin-${hadoop_version}.tgz"
  fi
  
  local url="$SPARK_MIRROR/spark-${version}/${filename}"
  
  log "Downloading Spark $version (${hadoop_version} compatible)"
  log "URL: $url"
  
  if ! curl -f -L --progress-bar -o "$dest_file" "$url"; then
    error "Download failed"
    log "Please verify:"
    log "  1. Version $version exists"
    log "  2. Hadoop version $hadoop_version is available for this Spark version"
    log "  3. You have network access"
    log "  4. Archive is available: $SPARK_MIRROR"
    return 1
  fi
  
  success "Downloaded to $dest_file"
}

# Extract and setup Spark
install_spark_from_tarball() {
  local tarball="$1"
  local version="$2"
  local install_dir="$3"
  
  if [[ ! -f "$tarball" ]]; then
    die "Tarball not found: $tarball"
  fi
  
  log "Extracting Spark to $install_dir"
  
  # Create installation directory
  create_dir "$install_dir"
  
  # Extract tarball
  if ! tar -xzf "$tarball" -C "$install_dir" --strip-components=1; then
    die "Failed to extract tarball"
  fi
  
  success "Spark $version installed to $install_dir"
  
  # Show version info
  if [[ -f "$install_dir/bin/spark-submit" ]]; then
    log "Spark version:"
    "$install_dir/bin/spark-submit" --version 2>&1 | grep -E "version|Using" | head -3 | sed 's/^/  /' || true
  fi
}

# Create symlink to current installation
create_current_symlink() {
  local install_dir="$1"
  local symlink_path="$SPARK_INSTALL_BASE/spark-current"
  
  if [[ -L "$symlink_path" ]]; then
    rm "$symlink_path"
  fi
  
  # Create relative symlink
  local relative_path
  relative_path=$(basename "$install_dir")
  
  (cd "$SPARK_INSTALL_BASE" && ln -s "$relative_path" spark-current)
  success "Created symlink: spark-current -> $relative_path"
}

# ============================================================================
# Main Installation Logic
# ============================================================================

main() {
  local version="$SPARK_VERSION"
  local hadoop_version="hadoop3"
  local install_base="$SPARK_INSTALL_BASE"
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
      --hadoop-version)
        hadoop_version="$2"
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
  
  header "Spark Installation"
  
  log "Version: $version"
  log "Hadoop compatibility: $hadoop_version"
  log "Installation base: $install_base"
  
  local install_dir="$install_base/spark-${version}"
  
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
  
  # Download Spark
  local temp_tarball
  temp_tarball=$(mktemp --suffix=.tgz)
  
  download_spark "$version" "$hadoop_version" "$temp_tarball"
  install_spark_from_tarball "$temp_tarball" "$version" "$install_dir"
  
  rm "$temp_tarball"
  
  # Create symlink
  create_current_symlink "$install_dir"
  
  # Show installation summary
  separator
  success "Spark installation complete!"
  log ""
  log "Installation directory: $install_dir"
  log "Current symlink:        $install_base/spark-current"
  log ""
  log "Next steps:"
  log "  1. Configure Spark: ./data-platform/spark/configure-spark.sh"
  log "  2. Test Spark: $install_base/spark-current/bin/spark-shell"
  log "  3. Start services: ./data-platform/spark/start-spark.sh"
  log ""
  log "Environment variable suggestions:"
  log "  export SPARK_HOME=$install_dir"
  log "  export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin"
}

# Run main function
main "$@"
