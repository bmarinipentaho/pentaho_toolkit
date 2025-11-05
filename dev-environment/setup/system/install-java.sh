#!/bin/bash
#
# Java Installation Script
# Installs OpenJDK and configures JAVA_HOME
#

set -euo pipefail

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$TOOLKIT_ROOT/lib/common.sh"

# Default Java version
JAVA_VERSION=${JAVA_VERSION:-21}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            JAVA_VERSION="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--version VERSION]"
            echo ""
            echo "Options:"
            echo "  --version VERSION    Java version to install (default: 21)"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

header "Java $JAVA_VERSION Installation"

# Check if already installed
if java -version 2>&1 | grep -q "openjdk version \"$JAVA_VERSION"; then
    success "OpenJDK $JAVA_VERSION is already installed"
    java -version
else
    log "Installing OpenJDK $JAVA_VERSION..."
    sudo apt-get update -y
    sudo apt-get install -y "openjdk-$JAVA_VERSION-jdk"
    success "OpenJDK $JAVA_VERSION installed"
fi

# Resolve JAVA_HOME
log "Configuring JAVA_HOME..."
JAVA_BIN_PATH=$(readlink -f /usr/bin/java)
JAVA_HOME_DIR="${JAVA_BIN_PATH%/bin/java}"

if [[ -z "$JAVA_HOME_DIR" ]] || [[ ! -d "$JAVA_HOME_DIR" ]]; then
    die "Unable to determine JAVA_HOME"
fi

log "JAVA_HOME will be set to: $JAVA_HOME_DIR"

# Update ~/.bashrc with JAVA_HOME
BASHRC_FILE=~/.bashrc

# Remove old block if exists
sed -i '/# BEGIN PENTAHO_TOOLKIT JAVA ENV/,/# END PENTAHO_TOOLKIT JAVA ENV/d' "$BASHRC_FILE" 2>/dev/null || true

# Add new block
cat <<EOL >> "$BASHRC_FILE"
# BEGIN PENTAHO_TOOLKIT JAVA ENV
export JAVA_HOME=$JAVA_HOME_DIR
export PATH=\$JAVA_HOME/bin:\$PATH
# END PENTAHO_TOOLKIT JAVA ENV
EOL

# Export for current session
export JAVA_HOME=$JAVA_HOME_DIR
export PATH=$JAVA_HOME/bin:$PATH

success "Java environment configured"
log "JAVA_HOME=$JAVA_HOME"
log "Java version:"
java -version

echo ""
log "Note: To use Java in new terminals, run: source ~/.bashrc"
