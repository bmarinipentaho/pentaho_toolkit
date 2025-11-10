#!/usr/bin/env bash
#
# Pentaho Server Utilities Library
#
# Shared functions for server detection, PID management, and status checking.
# Can be sourced by any script that needs to work with Pentaho Server.
#

# Get server PID
# Args: $1 = server_path (path to pentaho-server directory)
# Returns: PID if found, empty otherwise
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
# Args: $1 = server_path (path to pentaho-server directory)
# Returns: 0 if running, 1 if not
is_server_running() {
    local server_path="$1"
    local pid
    
    pid=$(get_server_pid "$server_path")
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Find all running servers in Pentaho base
# Args: $1 = pentaho_base (default: ~/pentaho)
# Prints: List of server paths that are running
find_running_servers() {
    local pentaho_base="${1:-$HOME/pentaho}"
    
    if [[ ! -d "$pentaho_base" ]]; then
        return 0
    fi
    
    # Find all pentaho-server directories
    find "$pentaho_base" -type d -name "pentaho-server" 2>/dev/null | while read -r server_path; do
        if is_server_running "$server_path"; then
            echo "$server_path"
        fi
    done
}

# Stop server gracefully
# Args: $1 = server_path (path to pentaho-server directory)
#       $2 = timeout in seconds (default: 60)
# Returns: 0 if stopped, 1 if failed
stop_server_gracefully() {
    local server_path="$1"
    local timeout="${2:-60}"
    local pid
    
    if ! is_server_running "$server_path"; then
        return 0
    fi
    
    pid=$(get_server_pid "$server_path")
    log "Stopping server (PID: $pid)..."
    
    # Try graceful shutdown with stop script
    local stop_script="$server_path/stop-pentaho.sh"
    if [[ -x "$stop_script" ]]; then
        "$stop_script" &>/dev/null || true
    else
        # Fallback: send TERM signal
        kill -TERM "$pid" 2>/dev/null || true
    fi
    
    # Wait for shutdown
    local count=0
    while [[ $count -lt $timeout ]]; do
        if ! is_server_running "$server_path"; then
            success "Server stopped successfully"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    # Force kill if still running
    if is_server_running "$server_path"; then
        warning "Server did not stop gracefully, forcing shutdown..."
        kill -9 "$pid" 2>/dev/null || true
        sleep 2
        
        if is_server_running "$server_path"; then
            error "Failed to stop server"
            return 1
        fi
    fi
    
    success "Server stopped"
    return 0
}

# Stop all running servers
# Args: $1 = pentaho_base (default: ~/pentaho)
# Returns: 0 if all stopped, 1 if any failed
stop_all_servers() {
    local pentaho_base="${1:-$HOME/pentaho}"
    local running_servers
    local failed=0
    
    running_servers=$(find_running_servers "$pentaho_base")
    
    if [[ -z "$running_servers" ]]; then
        log "No running servers found"
        return 0
    fi
    
    log "Found running servers, stopping them..."
    echo "$running_servers" | while read -r server_path; do
        log "Stopping: $server_path"
        if ! stop_server_gracefully "$server_path" 30; then
            failed=$((failed + 1))
        fi
    done
    
    return $failed
}
