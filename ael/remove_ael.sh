#!/bin/bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/.." && pwd)

PURGE_HDFS=0
PURGE_PDI=0
DRY_RUN=0
FORCE=0

usage() {
    cat <<EOF
Usage: $0 [options]
    --purge-hdfs      Remove pdi-spark-executor.zip from HDFS (/user/\$USER)
    --purge-pdi       Remove user Pentaho/Kettle artifacts (~/.kettle, ~/.pentaho, ~/.pentaho/metastore)
    --dry-run         Show what would be removed, but don't delete
    --force           Do not prompt for confirmation
    -h|--help         Show this help

Always attempts to stop Hadoop, Spark, and AEL daemon; removes local installs (HADOOP_HOME, SPARK_HOME, ael_deployment), env var exports, and tarballs.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge-hdfs) PURGE_HDFS=1; shift ;;
        --purge-pdi) PURGE_PDI=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        --force) FORCE=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
done

log() { echo "[remove] $*"; }
action() { if [ $DRY_RUN -eq 1 ]; then echo "DRY-RUN: $*"; else eval "$*"; fi }

confirm() {
    if [ $FORCE -eq 1 ]; then return 0; fi
    read -rp "Proceed with environment removal? (y/N) " ans
    [[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
}

confirm

###############################################################################
# Stop services
###############################################################################
stop_cmd() { if command -v "$1" >/dev/null 2>&1; then action "$1" || true; fi }

log "Stopping Hadoop services (if present)"
stop_cmd stop-dfs.sh
stop_cmd stop-yarn.sh

log "Stopping Spark History Server (if present)"
if command -v jps >/dev/null 2>&1; then
    for svc in HistoryServer; do
        pid=$(jps | awk -v s="$svc" '$2==s {print $1}')
        if [ -n "$pid" ]; then action "kill -9 $pid"; log "Killed $svc ($pid)"; fi
    done
fi

log "Stopping AEL daemon if running"
if pgrep -f spark-execution-daemon >/dev/null 2>&1; then
    # Try graceful stop via daemon.sh if path exists
    if [ -n "${AEL_HOME:-}" ] && [ -f "$AEL_HOME/data-integration/spark-execution-daemon/daemon.sh" ]; then
        (cd "$AEL_HOME/data-integration/spark-execution-daemon" && action "./daemon.sh stop" || true)
    fi
    # Fallback kill remaining processes
    pgrep -f spark-execution-daemon | while read -r p; do action "kill -9 $p"; done
fi

log "Stopping remaining Hadoop/YARN JVMs if still up"
if command -v jps >/dev/null 2>&1; then
    for service in NameNode DataNode SecondaryNameNode ResourceManager NodeManager; do
        pid=$(jps | awk -v s="$service" '$2==s {print $1}')
        if [ -n "$pid" ]; then action "kill -9 $pid"; log "Killed $service ($pid)"; fi
    done
fi

###############################################################################
# Local filesystem removals
###############################################################################

# Resolve deployment root (ael_deployment parent of AEL_HOME/AEL)
AEL_DEPLOY_ROOT=""
if [ -n "${AEL_HOME:-}" ]; then
    case "$AEL_HOME" in
        */AEL) AEL_DEPLOY_ROOT=${AEL_HOME%/AEL} ;;
        *) AEL_DEPLOY_ROOT=$AEL_HOME ;;
    esac
fi
[ -z "$AEL_DEPLOY_ROOT" ] && [ -d "$HOME/ael_deployment" ] && AEL_DEPLOY_ROOT="$HOME/ael_deployment"

remove_dir() { [ -n "$1" ] && [ -d "$1" ] && action "rm -rf '$1'" && log "Removed $1" || true; }

log "Removing Hadoop installation"
if [ -n "${HADOOP_HOME:-}" ] && [ -d "$HADOOP_HOME" ]; then action "sudo rm -rf '$HADOOP_HOME'"; fi

log "Removing Spark installation"
if [ -n "${SPARK_HOME:-}" ] && [ -d "$SPARK_HOME" ]; then action "sudo rm -rf '$SPARK_HOME'"; fi

log "Removing AEL deployment root"
remove_dir "$AEL_DEPLOY_ROOT"

log "Removing tarballs directory in repo (if exists)"
remove_dir "$REPO_ROOT/tarballs"

###############################################################################
# Optional purges
###############################################################################
if [ $PURGE_PDI -eq 1 ]; then
    log "Purging user Pentaho/Kettle artifacts"
    remove_dir "$HOME/.kettle"
    remove_dir "$HOME/.pentaho"
    remove_dir "$HOME/.pentaho/metastore"
fi

if [ $PURGE_HDFS -eq 1 ]; then
    if command -v hdfs >/dev/null 2>&1; then
        log "Purging HDFS pdi-spark-executor.zip"
        action "hdfs dfs -rm -f /user/$USER/pdi-spark-executor.zip" || true
    else
        log "hdfs command not found; skipping HDFS purge"
    fi
fi

###############################################################################
# Environment cleanup
###############################################################################
clean_env_file() {
    local f=$1
    [ -f "$f" ] || return 0
    action "sed -i '/^export AEL_HOME=/d' '$f'"
    action "sed -i '/^export HADOOP_HOME=/d' '$f'"
    action "sed -i '/^export SPARK_HOME=/d' '$f'"
    # Remove Hadoop and Spark block markers if present (original pattern)
    action "sed -i '/# Hadoop environment variables/,+12d' '$f'" || true
    action "sed -i '/# Spark environment variables/,+5d' '$f'" || true
}

log "Cleaning environment variable exports from shell init files"
clean_env_file "$HOME/.profile"
clean_env_file "$HOME/.bashrc"

unset AEL_HOME HADOOP_HOME SPARK_HOME || true

log "Cleanup complete." 
if [ $DRY_RUN -eq 1 ]; then
    echo "(Dry run: no files actually removed)"
fi

exit 0