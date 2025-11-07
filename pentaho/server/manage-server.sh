#!/usr/bin/env bash
#
# Pentaho Server Management Script
#
# Start, stop, and manage Pentaho Server instances.
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
SERVER_PORT=8080
KARAF_PORT=8181

# ============================================================================
# Functions
# ============================================================================

show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pentaho Server Management
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Start, stop, and manage Pentaho Server.

USAGE:
    $0 <COMMAND> [SERVER_PATH]

COMMANDS:
    start           Start Pentaho Server
    stop            Stop Pentaho Server
    restart         Restart Pentaho Server
    status          Check server status
    logs            Tail server logs
    karaf           Connect to Karaf console
    clean           Clean work directories

ARGUMENTS:
    SERVER_PATH     Path to pentaho-server or server-current symlink
                    If omitted, searches for server-current in latest version

EXAMPLES:
    # Start current server
    $0 start
    
    # Stop specific server
    $0 stop ~/pentaho/11.0.0.0/204/server-current
    
    # Check status
    $0 status
    
    # View logs
    $0 logs
    
    # Clean Tomcat work directories
    $0 clean ~/pentaho/11.0.0.0/204/server-current

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Find latest server installation
find_latest_server() {
    local latest_version latest_build server_current
    
    # Find latest version
    latest_version=$(find "$PENTAHO_BASE" -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | sort -V | tail -1)
    [[ -z "$latest_version" ]] && return 1
    
    # Find latest build
    latest_build=$(find "$latest_version" -maxdepth 1 -type d -name "[0-9]*" 2>/dev/null | sort -V | tail -1)
    [[ -z "$latest_build" ]] && return 1
    
    # Check for server-current
    server_current="$latest_build/server-current"
    if [[ -L "$server_current" ]]; then
        echo "$server_current"
        return 0
    fi
    
    # Fallback to pentaho-server directory
    if [[ -d "$latest_build/server/pentaho-server" ]]; then
        echo "$latest_build/server/pentaho-server"
        return 0
    fi
    
    return 1
}

# Get server PID
get_server_pid() {
    local server_path="$1"
    local catalina_pid="$server_path/tomcat/bin/catalina.pid"
    
    if [[ -f "$catalina_pid" ]]; then
        cat "$catalina_pid"
        return 0
    fi
    
    # Fallback: search for Tomcat process
    pgrep -f "catalina.*$(basename "$server_path")" 2>/dev/null | head -1
}

# Check if server is running
is_server_running() {
    local server_path="$1"
    local pid
    
    pid=$(get_server_pid "$server_path")
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Start server
start_server() {
    local server_path="$1"
    
    if is_server_running "$server_path"; then
        warning "Server already running"
        show_status "$server_path"
        return 0
    fi
    
    log "Starting Pentaho Server..."
    log "Server: $server_path"
    
    # Start script
    local start_script="$server_path/start-pentaho.sh"
    if [[ ! -f "$start_script" ]]; then
        die "Start script not found: $start_script"
    fi
    
    # Execute start script
    cd "$server_path"
    ./start-pentaho.sh
    
    # Wait for startup
    log "Waiting for server to start..."
    local attempts=0
    local max_attempts=30
    
    while [[ $attempts -lt $max_attempts ]]; do
        if netstat -tuln 2>/dev/null | grep -q ":$SERVER_PORT " || \
           ss -tuln 2>/dev/null | grep -q ":$SERVER_PORT "; then
            success "Server started successfully!"
            echo ""
            echo "Access: http://localhost:$SERVER_PORT/pentaho"
            echo "Karaf:  ssh://localhost:$KARAF_PORT (user: karaf, password: karaf)"
            return 0
        fi
        sleep 2
        ((attempts++))
    done
    
    warning "Server started but port $SERVER_PORT not yet available"
    log "Check logs: $server_path/tomcat/logs/catalina.out"
}

# Stop server
stop_server() {
    local server_path="$1"
    
    if ! is_server_running "$server_path"; then
        warning "Server not running"
        return 0
    fi
    
    log "Stopping Pentaho Server..."
    
    # Stop script
    local stop_script="$server_path/stop-pentaho.sh"
    if [[ ! -f "$stop_script" ]]; then
        die "Stop script not found: $stop_script"
    fi
    
    # Execute stop script
    cd "$server_path"
    ./stop-pentaho.sh
    
    # Wait for shutdown
    local pid
    pid=$(get_server_pid "$server_path")
    if [[ -n "$pid" ]]; then
        log "Waiting for shutdown (PID: $pid)..."
        local attempts=0
        local max_attempts=30
        
        while kill -0 "$pid" 2>/dev/null && [[ $attempts -lt $max_attempts ]]; do
            sleep 1
            ((attempts++))
        done
        
        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            warning "Graceful shutdown timeout, forcing stop..."
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
    
    success "Server stopped"
}

# Show status
show_status() {
    local server_path="$1"
    local pid
    
    header "Pentaho Server Status"
    echo "Server: $server_path"
    echo ""
    
    if is_server_running "$server_path"; then
        pid=$(get_server_pid "$server_path")
        success "Status: RUNNING (PID: $pid)"
        echo ""
        
        # Check ports
        if netstat -tuln 2>/dev/null | grep -q ":$SERVER_PORT " || \
           ss -tuln 2>/dev/null | grep -q ":$SERVER_PORT "; then
            success "Tomcat:  Port $SERVER_PORT (LISTENING)"
        else
            warning "Tomcat:  Port $SERVER_PORT (NOT LISTENING)"
        fi
        
        if netstat -tuln 2>/dev/null | grep -q ":$KARAF_PORT " || \
           ss -tuln 2>/dev/null | grep -q ":$KARAF_PORT "; then
            success "Karaf:   Port $KARAF_PORT (LISTENING)"
        else
            warning "Karaf:   Port $KARAF_PORT (NOT LISTENING)"
        fi
        
        echo ""
        echo "Access: http://localhost:$SERVER_PORT/pentaho"
    else
        error "Status: STOPPED"
    fi
}

# Tail logs
tail_logs() {
    local server_path="$1"
    local catalina_log="$server_path/tomcat/logs/catalina.out"
    
    if [[ ! -f "$catalina_log" ]]; then
        die "Log file not found: $catalina_log"
    fi
    
    log "Tailing: $catalina_log"
    log "Press Ctrl+C to exit"
    echo ""
    
    tail -f "$catalina_log"
}

# Connect to Karaf console
karaf_console() {
    local server_path="$1"
    
    if ! is_server_running "$server_path"; then
        die "Server not running. Start it first with: $0 start"
    fi
    
    log "Connecting to Karaf console..."
    log "Default credentials: karaf/karaf"
    echo ""
    
    # Check if sshpass is available
    if command -v sshpass &>/dev/null; then
        sshpass -p karaf ssh -o StrictHostKeyChecking=no -p "$KARAF_PORT" karaf@localhost
    else
        log "Install sshpass for automatic authentication, or use: ssh -p $KARAF_PORT karaf@localhost"
        ssh -o StrictHostKeyChecking=no -p "$KARAF_PORT" karaf@localhost
    fi
}

# Clean work directories
clean_server() {
    local server_path="$1"
    
    if is_server_running "$server_path"; then
        die "Cannot clean while server is running. Stop it first with: $0 stop"
    fi
    
    log "Cleaning server work directories..."
    
    local tomcat_work="$server_path/tomcat/work"
    local tomcat_temp="$server_path/tomcat/temp"
    local cache_dir="$server_path/pentaho-solutions/system/osgi/felix/cache"
    
    if [[ -d "$tomcat_work" ]]; then
        rm -rf "$tomcat_work"/*
        success "Cleaned: tomcat/work"
    fi
    
    if [[ -d "$tomcat_temp" ]]; then
        rm -rf "$tomcat_temp"/*
        success "Cleaned: tomcat/temp"
    fi
    
    if [[ -d "$cache_dir" ]]; then
        rm -rf "$cache_dir"/*
        success "Cleaned: osgi/felix/cache"
    fi
    
    success "Server cleaned"
}

# ============================================================================
# Main
# ============================================================================

main() {
    local command=""
    local server_path=""
    
    # Parse command
    if [[ $# -eq 0 ]]; then
        error "Command required"
        show_help
        exit 1
    fi
    
    command="$1"
    shift
    
    # Parse server path
    if [[ $# -gt 0 ]]; then
        server_path="$1"
        shift
    fi
    
    # Find server if not specified
    if [[ -z "$server_path" ]]; then
        if server_path=$(find_latest_server); then
            log "Using: $server_path"
        else
            die "No server installation found. Install server first or specify path."
        fi
    fi
    
    # Resolve symlink
    if [[ -L "$server_path" ]]; then
        server_path=$(readlink -f "$server_path")
    fi
    
    # Validate server path
    if [[ ! -d "$server_path" ]]; then
        die "Server directory not found: $server_path"
    fi
    
    if [[ ! -f "$server_path/start-pentaho.sh" ]]; then
        die "Not a valid pentaho-server directory"
    fi
    
    # Execute command
    case "$command" in
        start)
            start_server "$server_path"
            ;;
        stop)
            stop_server "$server_path"
            ;;
        restart)
            stop_server "$server_path"
            sleep 2
            start_server "$server_path"
            ;;
        status)
            show_status "$server_path"
            ;;
        logs)
            tail_logs "$server_path"
            ;;
        karaf)
            karaf_console "$server_path"
            ;;
        clean)
            clean_server "$server_path"
            ;;
        -h|--help)
            show_help
            ;;
        *)
            error "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
