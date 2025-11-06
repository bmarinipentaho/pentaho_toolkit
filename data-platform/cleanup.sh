#!/usr/bin/env bash
#
# Data Platform Cleanup Script
#
# Remove all Hadoop, Spark installations, data directories, and temporary files.

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

# ============================================================================
# Configuration
# ============================================================================

DATA_PLATFORM_BASE="${DATA_PLATFORM_BASE:-$HOME/data-platform}"

# ============================================================================
# Functions
# ============================================================================

show_help() {
  cat << EOF
Data Platform Cleanup Script

USAGE:
  $(basename "$0") [OPTIONS]

OPTIONS:
  --dry-run            Show what would be deleted without actually deleting
  --hadoop-only        Remove only Hadoop installations and data
  --spark-only         Remove only Spark installations and data
  --keep-logs          Preserve log files
  --auto-confirm       Skip confirmation prompt
  -h, --help           Show this help message

EXAMPLES:
  # Preview cleanup
  $(basename "$0") --dry-run

  # Remove everything with confirmation
  $(basename "$0")

  # Remove only Hadoop
  $(basename "$0") --hadoop-only --auto-confirm

  # Remove only Spark
  $(basename "$0") --spark-only --auto-confirm

CLEANUP TARGETS:
  - Hadoop installations:  $DATA_PLATFORM_BASE/installs/hadoop-*/
  - Spark installations:   $DATA_PLATFORM_BASE/installs/spark-*/
  - Hadoop data:           $DATA_PLATFORM_BASE/hadoop-data/
  - Spark work dirs:       $DATA_PLATFORM_BASE/spark-work/
  - Logs:                  $DATA_PLATFORM_BASE/logs/
  - Temp files:            /tmp/hadoop-*, /tmp/spark-*, /tmp/hsperfdata_*

EOF
}

# Calculate total size of cleanup targets
calculate_cleanup_size() {
  local total=0
  local path
  
  for path in "$@"; do
    if [[ -e "$path" ]]; then
      local size
      size=$(du -sb "$path" 2>/dev/null | cut -f1 || echo "0")
      total=$((total + size))
    fi
  done
  
  if command_exists numfmt; then
    numfmt --to=iec-i --suffix=B "$total"
  else
    echo "${total} bytes"
  fi
}

# ============================================================================
# Main Cleanup Logic
# ============================================================================

main() {
  local dry_run=false
  local hadoop_only=false
  local spark_only=false
  local keep_logs=false
  local auto_confirm=false
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        show_help
        exit 0
        ;;
      --dry-run)
        dry_run=true
        shift
        ;;
      --hadoop-only)
        hadoop_only=true
        shift
        ;;
      --spark-only)
        spark_only=true
        shift
        ;;
      --keep-logs)
        keep_logs=true
        shift
        ;;
      --auto-confirm)
        auto_confirm=true
        shift
        ;;
      *)
        error "Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  
  # Validate options
  if [[ "$hadoop_only" == true ]] && [[ "$spark_only" == true ]]; then
    die "Cannot use --hadoop-only and --spark-only together"
  fi
  
  header "Data Platform Cleanup"
  
  # Build cleanup list
  local cleanup_dirs=()
  local cleanup_patterns=()
  
  if [[ "$hadoop_only" != true ]]; then
    # Spark targets
    cleanup_dirs+=("$DATA_PLATFORM_BASE/installs/spark-"*)
    cleanup_dirs+=("$DATA_PLATFORM_BASE/spark-work")
    cleanup_patterns+=("/tmp/spark-*")
  fi
  
  if [[ "$spark_only" != true ]]; then
    # Hadoop targets
    cleanup_dirs+=("$DATA_PLATFORM_BASE/installs/hadoop-"*)
    cleanup_dirs+=("$DATA_PLATFORM_BASE/hadoop-data")
    cleanup_patterns+=("/tmp/hadoop-*")
    cleanup_patterns+=("/tmp/hsperfdata_*")
  fi
  
  # Common targets
  if [[ "$keep_logs" != true ]]; then
    cleanup_dirs+=("$DATA_PLATFORM_BASE/logs")
  fi
  
  # Show cleanup targets
  subheader "Cleanup Targets"
  
  log "Directories:"
  local found_any=false
  for dir in "${cleanup_dirs[@]}"; do
    if [[ -e "$dir" ]]; then
      local size
      size=$(du -sh "$dir" 2>/dev/null | cut -f1 || echo "???")
      log "  [EXISTS] $dir ($size)"
      found_any=true
    else
      log "  [SKIP]   $dir (not found)"
    fi
  done
  
  log ""
  log "File patterns:"
  for pattern in "${cleanup_patterns[@]}"; do
    # Use array to handle glob expansion safely
    local matches=()
    while IFS= read -r -d '' file; do
      matches+=("$file")
    done < <(find "$(dirname "$pattern")" -maxdepth 1 -name "$(basename "$pattern")" -print0 2>/dev/null)
    
    if [[ ${#matches[@]} -gt 0 ]]; then
      log "  [EXISTS] $pattern (${#matches[@]} matches)"
      found_any=true
    else
      log "  [SKIP]   $pattern (no matches)"
    fi
  done
  
  if [[ "$found_any" != true ]]; then
    separator
    success "Nothing to clean up - all target paths are already empty"
    exit 0
  fi
  
  # Calculate total size
  local total_size
  total_size=$(calculate_cleanup_size "${cleanup_dirs[@]}")
  
  separator
  warning "Total size to be removed: $total_size"
  separator
  
  # Dry run check
  if [[ "$dry_run" == true ]]; then
    log "Dry run complete - no files were deleted"
    exit 0
  fi
  
  # Confirm deletion
  if [[ "$auto_confirm" != true ]]; then
    echo ""
    if ! confirm "Proceed with deletion?"; then
      log "Cleanup cancelled"
      exit 0
    fi
  fi
  
  # Perform cleanup
  subheader "Performing Cleanup"
  
  # Determine mode description
  local mode="Complete cleanup"
  if [[ "$hadoop_only" == true ]]; then
    mode="Hadoop-only cleanup"
  elif [[ "$spark_only" == true ]]; then
    mode="Spark-only cleanup"
  fi
  if [[ "$keep_logs" == true ]]; then
    mode="$mode (preserving logs)"
  fi
  log "Mode: $mode"
  
  # Remove directories
  for dir in "${cleanup_dirs[@]}"; do
    if [[ -e "$dir" ]]; then
      log "Removing: $dir"
      rm -rf "$dir" && success "Removed: $dir" || error "Failed to remove: $dir"
    fi
  done
  
  # Remove pattern matches
  for pattern in "${cleanup_patterns[@]}"; do
    while IFS= read -r -d '' file; do
      log "Removing: $file"
      rm -rf "$file" && success "Removed: $file" || error "Failed to remove: $file"
    done < <(find "$(dirname "$pattern")" -maxdepth 1 -name "$(basename "$pattern")" -print0 2>/dev/null)
  done
  
  separator
  success "Cleanup complete!"
  log ""
  log "Checking for remaining data platform files..."
  
  # Verify cleanup
  local remaining=false
  for dir in "${cleanup_dirs[@]}"; do
    if [[ -e "$dir" ]]; then
      warning "Still exists: $dir"
      remaining=true
    fi
  done
  
  if [[ "$remaining" != true ]]; then
    success "All data platform files removed successfully"
  else
    warning "Some files could not be removed (see above)"
  fi
}

# Run main function
main "$@"
