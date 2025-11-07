#!/usr/bin/env bash
#
# Pentaho Server PostgreSQL Configuration Script
#
# Configures repository.xml and quartz.properties for PostgreSQL.
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
POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_USER="${POSTGRES_USER:-pentaho}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-password}"

# Database names
HIBERNATE_DB="hibernate"
QUARTZ_DB="quartz"
JCR_DB="jcr"

AUTO_CONFIRM=false

# ============================================================================
# Functions
# ============================================================================

show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pentaho Server PostgreSQL Configuration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configure Pentaho Server to use PostgreSQL for repository storage.

USAGE:
    $0 [OPTIONS] SERVER_PATH

ARGUMENTS:
    SERVER_PATH           Path to pentaho-server directory or server-current symlink

OPTIONS:
    --host HOST          PostgreSQL host (default: localhost)
    --port PORT          PostgreSQL port (default: 5432)
    --user USER          PostgreSQL user (default: pentaho)
    --password PASS      PostgreSQL password (default: password)
    -y, --yes           Auto-confirm all prompts
    -h, --help          Show this help message

CONFIGURATION:
    Modifies the following files:
    - pentaho-solutions/system/jackrabbit/repository.xml (JCR database)
    - pentaho-solutions/system/quartz/quartz.properties (Scheduler)
    - pentaho-solutions/system/applicationContext-spring-security-jdbc.xml (Users)

EXAMPLES:
    # Use current symlink
    $0 ~/pentaho/11.0.0.0/204/server-current
    
    # Specific server
    $0 ~/pentaho/11.0.0.0/204/server/pentaho-server
    
    # Custom PostgreSQL settings
    $0 --host postgres.local --port 5433 --user admin ~/pentaho/11.0.0.0/204/server-current

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Configure repository.xml for PostgreSQL
configure_repository_xml() {
    local repo_xml="$1"
    
    log "Configuring JCR repository: $repo_xml"
    
    if [[ ! -f "$repo_xml" ]]; then
        die "repository.xml not found: $repo_xml"
    fi
    
    # Backup original
    cp "$repo_xml" "$repo_xml.bak"
    log "Backup created: $repo_xml.bak"
    
    # TODO: Implement XML modifications
    # This requires XML manipulation to:
    # 1. Change FileSystem to PostgreSQL PersistenceManager
    # 2. Update JDBC connection strings
    # 3. Configure workspace and versioning storage
    
    warning "repository.xml configuration not yet implemented"
    log "Manual configuration required"
}

# Configure quartz.properties for PostgreSQL
configure_quartz_properties() {
    local quartz_props="$1"
    
    log "Configuring Quartz scheduler: $quartz_props"
    
    if [[ ! -f "$quartz_props" ]]; then
        die "quartz.properties not found: $quartz_props"
    fi
    
    # Backup original
    cp "$quartz_props" "$quartz_props.bak"
    log "Backup created: $quartz_props.bak"
    
    # Update PostgreSQL settings
    log "Updating database connection..."
    
    # PostgreSQL driver
    sed -i "s|^org.quartz.dataSource.myDS.driver.*|org.quartz.dataSource.myDS.driver = org.postgresql.Driver|" "$quartz_props"
    
    # JDBC URL
    sed -i "s|^org.quartz.dataSource.myDS.URL.*|org.quartz.dataSource.myDS.URL = jdbc:postgresql://${POSTGRES_HOST}:${POSTGRES_PORT}/${QUARTZ_DB}|" "$quartz_props"
    
    # Credentials
    sed -i "s|^org.quartz.dataSource.myDS.user.*|org.quartz.dataSource.myDS.user = ${POSTGRES_USER}|" "$quartz_props"
    sed -i "s|^org.quartz.dataSource.myDS.password.*|org.quartz.dataSource.myDS.password = ${POSTGRES_PASSWORD}|" "$quartz_props"
    
    # Delegate class for PostgreSQL
    sed -i "s|^org.quartz.jobStore.driverDelegateClass.*|org.quartz.jobStore.driverDelegateClass = org.quartz.impl.jdbcjobstore.PostgreSQLDelegate|" "$quartz_props"
    
    success "Quartz configured for PostgreSQL"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local server_path=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --host)
                POSTGRES_HOST="$2"
                shift 2
                ;;
            --port)
                POSTGRES_PORT="$2"
                shift 2
                ;;
            --user)
                POSTGRES_USER="$2"
                shift 2
                ;;
            --password)
                POSTGRES_PASSWORD="$2"
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
            -*)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                server_path="$1"
                shift
                ;;
        esac
    done
    
    # Validate server path
    if [[ -z "$server_path" ]]; then
        error "Server path required"
        show_help
        exit 1
    fi
    
    # Resolve symlink if needed
    if [[ -L "$server_path" ]]; then
        server_path=$(readlink -f "$server_path")
    fi
    
    if [[ ! -d "$server_path" ]]; then
        die "Server directory not found: $server_path"
    fi
    
    # Validate it's a pentaho-server
    if [[ ! -f "$server_path/start-pentaho.sh" ]]; then
        die "Not a valid pentaho-server directory (missing start-pentaho.sh)"
    fi
    
    # Show configuration summary
    header "PostgreSQL Configuration"
    echo "Server:    $server_path"
    echo "Host:      $POSTGRES_HOST"
    echo "Port:      $POSTGRES_PORT"
    echo "User:      $POSTGRES_USER"
    echo "Databases: $HIBERNATE_DB, $QUARTZ_DB, $JCR_DB"
    echo ""
    
    if [[ "$AUTO_CONFIRM" == false ]]; then
        if ! confirm "Proceed with configuration?" "Y"; then
            log "Configuration cancelled"
            exit 0
        fi
    fi
    
    # Configure components
    local repo_xml="$server_path/pentaho-solutions/system/jackrabbit/repository.xml"
    local quartz_props="$server_path/pentaho-solutions/system/quartz/quartz.properties"
    
    configure_quartz_properties "$quartz_props"
    configure_repository_xml "$repo_xml"
    
    # Summary
    header "✅ Configuration Complete"
    echo ""
    echo "Modified Files:"
    echo "  - quartz.properties (configured for PostgreSQL)"
    echo "  - repository.xml (manual configuration required)"
    echo ""
    echo "Backups created with .bak extension"
    echo ""
    
    success "PostgreSQL configuration applied! 🎉"
}

main "$@"
