#!/bin/bash
# Common functions and utilities for Pentaho setup scripts
# Source this file in other scripts: source "$(dirname "$0")/../lib/common.sh"

# Color definitions
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'

# Unicode symbols
readonly SYMBOL_CHECK="✓"
readonly SYMBOL_CROSS="✗"
readonly SYMBOL_ARROW="→"
readonly SYMBOL_INFO="ℹ"
readonly SYMBOL_WARN="⚠"

# Logging functions
log() {
    echo -e "${COLOR_CYAN}[INFO]${COLOR_RESET} $*"
}

success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $*"
}

error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $*" >&2
}

warning() {
    echo -e "${COLOR_YELLOW}[WARNING]${COLOR_RESET} $*"
}

header() {
    echo ""
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BOLD}$*${COLOR_RESET}"
    echo -e "${COLOR_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

subheader() {
    echo ""
    echo -e "${COLOR_BLUE}──────────────────────────────────────────────────────────────────────────────${COLOR_RESET}"
    echo -e "${COLOR_BLUE}$*${COLOR_RESET}"
    echo -e "${COLOR_BLUE}──────────────────────────────────────────────────────────────────────────────${COLOR_RESET}"
}

# Error handling
die() {
    error "$*"
    exit 1
}

# Check if running as root (and exit if so - we want sudo when needed)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        die "This script should not be run as root. Run as a normal user; sudo will be used when needed."
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if a package is installed (dpkg)
package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | /bin/grep -q "install ok installed"
}

# Confirm action (unless auto-confirm is enabled)
# Usage: confirm "Do you want to continue?" || exit 0
confirm() {
    local message="$1"
    local default="${2:-N}"  # Default to No if not specified
    
    if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
        log "Auto-confirm enabled: $message [YES]"
        return 0
    fi
    
    local prompt
    if [[ "$default" == "Y" ]]; then
        prompt="$message (Y/n): "
    else
        prompt="$message (y/N): "
    fi
    
    read -p "$prompt" -r
    
    if [[ "$default" == "Y" ]]; then
        [[ $REPLY =~ ^[Nn]$ ]] && return 1 || return 0
    else
        [[ $REPLY =~ ^[Yy]$ ]] && return 0 || return 1
    fi
}

# Wait for a service to be ready
# Usage: wait_for_service "PostgreSQL" "localhost" 5432 30
wait_for_service() {
    local service_name="$1"
    local host="$2"
    local port="$3"
    local max_attempts="${4:-30}"
    local attempt=0
    
    log "Waiting for $service_name to be ready..."
    
    while ! nc -z "$host" "$port" 2>/dev/null; do
        attempt=$((attempt + 1))
        if [[ $attempt -ge $max_attempts ]]; then
            error "$service_name did not become ready after $max_attempts attempts"
            return 1
        fi
        sleep 1
    done
    
    success "$service_name is ready"
    return 0
}

# Check Docker is running
check_docker_running() {
    if ! docker info &> /dev/null; then
        error "Docker is not running or you don't have permission to access it"
        error "Try: sudo usermod -aG docker $USER && newgrp docker"
        return 1
    fi
    return 0
}

# Progress indicator for long-running operations
show_progress() {
    local message="$1"
    echo -ne "${COLOR_CYAN}${message}${COLOR_RESET}"
}

clear_progress() {
    echo -e "\r\033[K"
}

# Print a separator line
separator() {
    echo -e "${COLOR_BLUE}────────────────────────────────────────────────────────────────────────────────${COLOR_RESET}"
}

# Create directory with logging
create_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" && log "Created directory: $dir" || die "Failed to create directory: $dir"
    fi
}

# Export functions and variables for use in other scripts
export -f log success error warning header subheader die
export -f check_not_root command_exists package_installed confirm
export -f wait_for_service check_docker_running
export -f show_progress clear_progress separator create_dir

# Export color variables
export COLOR_RED COLOR_GREEN COLOR_YELLOW COLOR_BLUE COLOR_MAGENTA COLOR_CYAN COLOR_RESET COLOR_BOLD
export SYMBOL_CHECK SYMBOL_CROSS SYMBOL_ARROW SYMBOL_INFO SYMBOL_WARN
