#!/usr/bin/env bash
#
# Pentaho Environment Cleanup Script
#
# Removes all Pentaho-related installations, caches, temp files, and hidden folders
# Use with caution - this will delete all PDI installations and configurations!
#
# Features:
#   - Removes PDI installations
#   - Clears Kettle/PDI caches and temp files
#   - Removes hidden Pentaho folders (.pentaho, .kettle, etc.)
#   - Dry-run mode to preview what will be deleted
#   - Selective cleanup options

set -euo pipefail

# ============================================================================
# Path Resolution
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source shared library
# shellcheck source=../lib/common.sh
if [[ -f "$TOOLKIT_ROOT/lib/common.sh" ]]; then
  source "$TOOLKIT_ROOT/lib/common.sh"
else
  echo "ERROR: Cannot find lib/common.sh at $TOOLKIT_ROOT/lib/common.sh" >&2
  exit 1
fi

# Source server utilities for stopping running servers
if [[ -f "$SCRIPT_DIR/server/lib/server-utils.sh" ]]; then
  source "$SCRIPT_DIR/server/lib/server-utils.sh"
fi

# ============================================================================
# Configuration
# ============================================================================

PDI_INSTALL_BASE="${PDI_INSTALL_BASE:-$HOME/pentaho/pdi}"
SERVER_INSTALL_BASE="${SERVER_INSTALL_BASE:-$HOME/pentaho}"
DRY_RUN=false
AUTO_CONFIRM=false

# ============================================================================
# Cleanup Targets
# ============================================================================

# Array of directories to remove
declare -a CLEANUP_DIRS=(
  # PDI installations
  "$PDI_INSTALL_BASE"
  
  # Server installations (will be filtered for server subdirectories)
  # Added dynamically based on options
  
  # Hidden Pentaho directories
  "$HOME/.pentaho"
  "$HOME/.kettle"
  
  # Temp directories
  "$HOME/.pentaho-tmp"
  "/tmp/pentaho"
  "/tmp/kettle"
  
  # Cache directories
  "$HOME/.pentaho/cache"
  "$HOME/.pentaho/metastore"
  
  # Logs (optional - will ask)
  "$HOME/.pentaho/logs"
  "$HOME/.kettle/logs"
)

# Individual cache and temp patterns
declare -a CLEANUP_PATTERNS=(
  "$HOME/.pentaho/*.log"
  "$HOME/.kettle/*.log"
  "/tmp/vfs_cache*"
  "/tmp/kettle_*"
  "/tmp/pdi_*"
)

# ============================================================================
# Functions
# ============================================================================

show_help() {
  cat << EOF
Pentaho Environment Cleanup Script

USAGE:
  $(basename "$0") [OPTIONS]

OPTIONS:
  --dry-run                 Show what would be deleted without deleting
  --pdi-only               Only remove PDI installations (keep configs/caches)
  --server-only            Only remove Server installations
  --caches-only            Only remove caches and temp files
  --all                    Remove everything (default)
  --keep-logs              Don't delete log files
  --auto-confirm           Skip confirmation prompts (use with caution!)
  -h, --help               Show this help message

CLEANUP TARGETS:
  PDI Installations:
    - $PDI_INSTALL_BASE

  Server Installations:
    - ~/pentaho/*/*/server/ (all server installations)

  Configuration & Hidden Folders:
    - ~/.pentaho
    - ~/.kettle

  Caches & Temp Files:
    - ~/.pentaho/cache
    - ~/.pentaho/metastore
    - /tmp/pentaho, /tmp/kettle
    - /tmp/vfs_cache*
    - /tmp/kettle_*, /tmp/pdi_*

  Logs (optional):
    - ~/.pentaho/logs
    - ~/.kettle/logs
    - ~/.pentaho/*.log
    - ~/.kettle/*.log

EXAMPLES:
  # Preview what will be deleted
  $(basename "$0") --dry-run

  # Remove only PDI installations
  $(basename "$0") --pdi-only

  # Remove only Server installations
  $(basename "$0") --server-only

  # Clean everything except logs
  $(basename "$0") --keep-logs

  # Full cleanup without prompts (DANGEROUS!)
  $(basename "$0") --all --auto-confirm

EOF
}

# Calculate total size of cleanup targets
calculate_cleanup_size() {
  local total_size=0
  
  for dir in "${CLEANUP_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      local size
      size=$(du -sb "$dir" 2>/dev/null | cut -f1) || size=0
      total_size=$((total_size + size))
    fi
  done
  
  # Convert to human readable
  if command_exists numfmt; then
    numfmt --to=iec-i --suffix=B "$total_size"
  else
    echo "$total_size bytes"
  fi
}

# List what will be deleted
list_cleanup_targets() {
  local found_items=false
  
  subheader "Cleanup Targets"
  
  log "Directories:"
  for dir in "${CLEANUP_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
      local size
      size=$(du -sh "$dir" 2>/dev/null | cut -f1) || size="unknown"
      log "  [EXISTS] $dir ($size)"
      found_items=true
    else
      log "  [SKIP]   $dir (not found)"
    fi
  done
  
  log ""
  log "File patterns:"
  for pattern in "${CLEANUP_PATTERNS[@]}"; do
    local files
    # shellcheck disable=SC2086
    files=$(ls -1 $pattern 2>/dev/null || true)
    if [[ -n "$files" ]]; then
      local count
      count=$(echo "$files" | wc -l)
      log "  [EXISTS] $pattern ($count files)"
      found_items=true
    else
      log "  [SKIP]   $pattern (no matches)"
    fi
  done
  
  if [[ "$found_items" == false ]]; then
    success "No Pentaho files found - environment is already clean!"
    return 1
  fi
  
  return 0
}

# Remove a directory
remove_directory() {
  local dir="$1"
  
  if [[ ! -d "$dir" ]]; then
    return 0
  fi
  
  if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would remove: $dir"
  else
    log "Removing: $dir"
    rm -rf "$dir"
    success "Removed: $dir"
  fi
}

# Remove files matching pattern
remove_pattern() {
  local pattern="$1"
  
  # shellcheck disable=SC2086
  local files
  files=$(ls -1 $pattern 2>/dev/null || true)
  
  if [[ -z "$files" ]]; then
    return 0
  fi
  
  if [[ "$DRY_RUN" == true ]]; then
    log "[DRY-RUN] Would remove files matching: $pattern"
    echo "$files" | while read -r file; do
      log "  - $file"
    done
  else
    log "Removing files matching: $pattern"
    # shellcheck disable=SC2086
    rm -f $pattern
    success "Removed files matching: $pattern"
  fi
}

# Perform cleanup
perform_cleanup() {
  local cleanup_mode="$1"
  local keep_logs="$2"
  
  header "Pentaho Cleanup"
  
  if [[ "$DRY_RUN" == true ]]; then
    warning "DRY-RUN MODE - No files will be deleted"
  fi
  
  # Check for running servers and stop them
  if [[ "$DRY_RUN" != true ]] && command -v find_running_servers &>/dev/null; then
    local running_servers
    running_servers=$(find_running_servers "$SERVER_INSTALL_BASE")
    
    if [[ -n "$running_servers" ]]; then
      warning "Found running Pentaho servers that must be stopped"
      echo "$running_servers" | while read -r server; do
        log "  • $(basename "$(dirname "$server")")/$(basename "$server")"
      done
      
      log ""
      if ! confirm "Stop running servers before cleanup?"; then
        error "Cannot proceed with cleanup while servers are running"
        exit 1
      fi
      
      stop_all_servers "$SERVER_INSTALL_BASE" || die "Failed to stop all servers"
      separator
    fi
  fi
  
  # Show what will be cleaned
  if ! list_cleanup_targets; then
    return 0
  fi
  
  separator
  
  # Calculate total size
  local total_size
  total_size=$(calculate_cleanup_size)
  warning "Total size to be removed: $total_size"
  
  # Confirm unless auto-confirm is set
  if [[ "$AUTO_CONFIRM" != true ]] && [[ "$DRY_RUN" != true ]]; then
    log ""
    if ! confirm "Proceed with cleanup?"; then
      log "Cleanup cancelled"
      return 0
    fi
  fi
  
  separator
  subheader "Performing Cleanup"
  
  # Remove based on mode
  case $cleanup_mode in
    pdi-only)
      log "Mode: PDI installations only"
      remove_directory "$PDI_INSTALL_BASE"
      ;;
      
    server-only)
      log "Mode: Server installations only"
      # Find and remove all server installations
      if [[ -d "$SERVER_INSTALL_BASE" ]]; then
        find "$SERVER_INSTALL_BASE" -type d -path "*/*/server" 2>/dev/null | while read -r server_dir; do
          remove_directory "$server_dir"
        done
      fi
      ;;
      
    caches-only)
      log "Mode: Caches and temp files only"
      remove_directory "$HOME/.pentaho/cache"
      remove_directory "$HOME/.pentaho/metastore"
      remove_directory "/tmp/pentaho"
      remove_directory "/tmp/kettle"
      
      for pattern in "${CLEANUP_PATTERNS[@]}"; do
        if [[ "$keep_logs" == true ]] && [[ "$pattern" == *".log"* ]]; then
          continue
        fi
        remove_pattern "$pattern"
      done
      ;;
      
    all)
      log "Mode: Complete cleanup"
      
      for dir in "${CLEANUP_DIRS[@]}"; do
        # Skip log directories if keep_logs is true
        if [[ "$keep_logs" == true ]] && [[ "$dir" == *"/logs" ]]; then
          log "Keeping logs: $dir"
          continue
        fi
        
        remove_directory "$dir"
      done
      
      # Remove all server installations
      if [[ -d "$SERVER_INSTALL_BASE" ]]; then
        find "$SERVER_INSTALL_BASE" -type d -path "*/*/server" 2>/dev/null | while read -r server_dir; do
          remove_directory "$server_dir"
        done
      fi
      
      for pattern in "${CLEANUP_PATTERNS[@]}"; do
        if [[ "$keep_logs" == true ]] && [[ "$pattern" == *".log"* ]]; then
          continue
        fi
        remove_pattern "$pattern"
      done
      ;;
  esac
  
  separator
  
  if [[ "$DRY_RUN" == true ]]; then
    success "Dry-run complete - no files were deleted"
    log "Run without --dry-run to actually perform cleanup"
  else
    success "Cleanup complete!"
    
    # Show remaining Pentaho files
    log ""
    log "Checking for remaining Pentaho files..."
    local remaining=false
    
    for dir in "${CLEANUP_DIRS[@]}"; do
      if [[ -d "$dir" ]]; then
        log "  Still exists: $dir"
        remaining=true
      fi
    done
    
    if [[ "$remaining" == false ]]; then
      success "All Pentaho files removed successfully"
    fi
  fi
}

# ============================================================================
# Main
# ============================================================================

main() {
  local cleanup_mode="all"
  local keep_logs=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      --pdi-only)
        cleanup_mode="pdi-only"
        shift
        ;;
      --server-only)
        cleanup_mode="server-only"
        shift
        ;;
      --caches-only)
        cleanup_mode="caches-only"
        shift
        ;;
      --all)
        cleanup_mode="all"
        shift
        ;;
      --keep-logs)
        keep_logs=true
        shift
        ;;
      --auto-confirm)
        AUTO_CONFIRM=true
        shift
        ;;
      *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  
  perform_cleanup "$cleanup_mode" "$keep_logs"
}

# Run main function
main "$@"
