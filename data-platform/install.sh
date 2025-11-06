#!/bin/bash
#
# Data Platform Installation
# Orchestrates Hadoop and Spark installation
#

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly TOOLKIT_ROOT

# Source common functions
source "$TOOLKIT_ROOT/lib/common.sh"

# Default settings
INSTALL_HADOOP=true
INSTALL_SPARK=true
HADOOP_VERSION="${HADOOP_VERSION:-3.4.1}"
SPARK_VERSION="${SPARK_VERSION:-4.0.0}"
AUTO_CONFIRM=false

# Function to show usage
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Data Platform Installation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Installs Hadoop and Spark for big data processing and AEL support.

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --hadoop-only           Install only Hadoop (skip Spark)
    --spark-only           Install only Spark (skip Hadoop)
    --hadoop-version VER   Hadoop version to install (default: $HADOOP_VERSION)
    --spark-version VER    Spark version to install (default: $SPARK_VERSION)
    -y, --yes              Auto-confirm all prompts
    -h, --help             Show this help message

ENVIRONMENT VARIABLES:
    HADOOP_VERSION         Override default Hadoop version
    SPARK_VERSION          Override default Spark version
    DATA_PLATFORM_BASE     Base directory for installations (default: ~/data-platform/installs)

EXAMPLES:
    # Install both with defaults
    $0

    # Install only Hadoop
    $0 --hadoop-only

    # Install with specific versions
    $0 --hadoop-version 3.3.6 --spark-version 3.5.4

    # Non-interactive installation
    $0 -y

INSTALLATION PATHS:
    Hadoop:  ~/data-platform/installs/hadoop-{version}/
    Spark:   ~/data-platform/installs/spark-{version}/
    
    Symlinks:
    - hadoop-current -> hadoop-{version}
    - spark-current -> spark-{version}

PREREQUISITES:
    - Java 21 (OpenJDK)
    - curl, tar
    - ~3GB disk space

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --hadoop-only)
            INSTALL_SPARK=false
            shift
            ;;
        --spark-only)
            INSTALL_HADOOP=false
            shift
            ;;
        --hadoop-version)
            HADOOP_VERSION="$2"
            shift 2
            ;;
        --spark-version)
            SPARK_VERSION="$2"
            shift 2
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
        *)
            error "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Main header
header "🚀 Data Platform Installation"

# Show installation plan
log "Installation plan:"
if [[ "$INSTALL_HADOOP" == true ]]; then
    echo "  ✓ Hadoop $HADOOP_VERSION"
fi
if [[ "$INSTALL_SPARK" == true ]]; then
    echo "  ✓ Spark $SPARK_VERSION"
fi
echo ""

# Confirm unless auto-confirm
if [[ "$AUTO_CONFIRM" == false ]]; then
    if ! confirm "Proceed with installation?" "Y"; then
        log "Installation cancelled by user"
        exit 0
    fi
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Hadoop Installation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$INSTALL_HADOOP" == true ]]; then
    header "Installing Hadoop $HADOOP_VERSION"
    
    if "$SCRIPT_DIR/hadoop/install-hadoop.sh" --version "$HADOOP_VERSION"; then
        success "Hadoop $HADOOP_VERSION installed successfully"
    else
        die "Hadoop installation failed"
    fi
    echo ""
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Spark Installation
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

if [[ "$INSTALL_SPARK" == true ]]; then
    header "Installing Spark $SPARK_VERSION"
    
    if "$SCRIPT_DIR/spark/install-spark.sh" --version "$SPARK_VERSION"; then
        success "Spark $SPARK_VERSION installed successfully"
    else
        die "Spark installation failed"
    fi
    echo ""
fi

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Installation Complete
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

header "✅ Data Platform Installation Complete"

log "Components installed:"
if [[ "$INSTALL_HADOOP" == true ]]; then
    echo "  ✓ Hadoop $HADOOP_VERSION"
    echo "    Location: ~/data-platform/installs/hadoop-$HADOOP_VERSION"
    echo "    Symlink:  ~/data-platform/installs/hadoop-current"
fi
if [[ "$INSTALL_SPARK" == true ]]; then
    echo "  ✓ Spark $SPARK_VERSION"
    echo "    Location: ~/data-platform/installs/spark-$SPARK_VERSION"
    echo "    Symlink:  ~/data-platform/installs/spark-current"
fi
echo ""

log "Next steps:"
if [[ "$INSTALL_HADOOP" == true ]]; then
    echo "  1. Configure Hadoop: cd data-platform/hadoop && ./configure-hadoop.sh"
fi
if [[ "$INSTALL_SPARK" == true ]]; then
    echo "  2. Configure Spark: cd data-platform/spark && ./configure-spark.sh"
fi
echo ""

log "Environment variables to add to your shell profile:"
if [[ "$INSTALL_HADOOP" == true ]]; then
    echo "  export HADOOP_HOME=\$HOME/data-platform/installs/hadoop-current"
    echo "  export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin"
fi
if [[ "$INSTALL_SPARK" == true ]]; then
    echo "  export SPARK_HOME=\$HOME/data-platform/installs/spark-current"
    echo "  export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin"
fi
echo ""

success "Installation complete! 🎉"
