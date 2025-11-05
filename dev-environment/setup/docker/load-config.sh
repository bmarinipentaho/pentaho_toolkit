#!/bin/bash
# load-config.sh - Load Docker environment configuration
# Usage: source load-config.sh

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default config file location
DEFAULT_CONFIG_FILE="$SCRIPT_DIR/.env"
CONFIG_FILE="${PENTAHO_CONFIG_FILE:-$DEFAULT_CONFIG_FILE}"

# Function to load configuration
load_config() {
    local config_file="$1"
    
    if [[ -f "$config_file" ]]; then
        echo "Loading configuration from: $config_file" >&2
        
        # Read the config file and export variables
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            if [[ $key =~ ^[[:space:]]*# ]] || [[ -z "$key" ]]; then
                continue
            fi
            
            # Remove any trailing comments
            value=$(echo "$value" | cut -d'#' -f1 | sed 's/[[:space:]]*$//')
            
            # Only set if not already set in environment
            if [[ -z "${!key:-}" ]]; then
                export "$key=$value"
            fi
        done < "$config_file"
        
        echo "Configuration loaded successfully" >&2
    else
        echo "Warning: Config file not found: $config_file" >&2
        echo "Using environment variables or defaults" >&2
    fi
}

# Function to show current configuration
show_config() {
    echo "Current Docker Environment Configuration:"
    echo "========================================"
    echo "PostgreSQL Version: ${POSTGRES_VERSION:-not set}"
    echo "Hadoop Version: ${HADOOP_VERSION:-not set}"
    echo "Spark Version: ${SPARK_VERSION:-not set}"
    echo "Network Name: ${DOCKER_NETWORK_NAME:-not set}"
    echo ""
    echo "HDFS Ports:"
    echo "  NameNode Web: ${HDFS_NAMENODE_WEB_PORT:-not set}"
    echo "  DataNode Web: ${HDFS_DATANODE_WEB_PORT:-not set}"
    echo ""
    echo "Spark Ports:"
    echo "  Master Web: ${SPARK_MASTER_WEB_PORT:-not set}"
    echo "  Worker Web: ${SPARK_WORKER_WEB_PORT:-not set}"
    echo "  History Server: ${SPARK_HISTORY_SERVER_PORT:-not set}"
    echo ""
    echo "Resource Limits:"
    echo "  Hadoop Memory: ${HADOOP_MEMORY_LIMIT:-not set}"
    echo "  Spark Memory: ${SPARK_MEMORY_LIMIT:-not set}"
    echo "  Spark Driver Memory: ${SPARK_DRIVER_MEMORY:-not set}"
    echo "  Spark Executor Memory: ${SPARK_EXECUTOR_MEMORY:-not set}"
    echo "========================================"
}

# Function to validate required versions
validate_versions() {
    local errors=0
    
    echo "Validating configuration..." >&2
    
    # Check Hadoop version format (should be like 3.4.1)
    if [[ ! "$HADOOP_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid Hadoop version format: $HADOOP_VERSION (expected: x.y.z)" >&2
        ((errors++))
    fi
    
    # Check Spark version format (should be like 4.0.0)
    if [[ ! "$SPARK_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid Spark version format: $SPARK_VERSION (expected: x.y.z)" >&2
        ((errors++))
    fi
    
    # Check if ports are numeric
    for port in HDFS_NAMENODE_WEB_PORT HDFS_DATANODE_WEB_PORT SPARK_MASTER_WEB_PORT SPARK_WORKER_WEB_PORT SPARK_HISTORY_SERVER_PORT; do
        if [[ ! "${!port}" =~ ^[0-9]+$ ]]; then
            echo "Error: Invalid port number for $port: ${!port}" >&2
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        echo "Configuration validation passed" >&2
        return 0
    else
        echo "Configuration validation failed with $errors errors" >&2
        return 1
    fi
}

# Auto-load configuration when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    load_config "$CONFIG_FILE"
else
    # Script is being executed directly
    echo "load-config.sh - Docker Environment Configuration Loader"
    echo ""
    echo "Usage:"
    echo "  source load-config.sh                    # Load configuration"
    echo "  ./load-config.sh show                   # Show current config"
    echo "  ./load-config.sh validate               # Validate config"
    echo "  PENTAHO_CONFIG_FILE=custom.env source load-config.sh"
    echo ""
    
    case "${1:-load}" in
        show)
            load_config "$CONFIG_FILE"
            show_config
            ;;
        validate)
            load_config "$CONFIG_FILE"
            validate_versions
            ;;
        load|*)
            load_config "$CONFIG_FILE"
            echo "Configuration loaded. Source this script to use in other scripts."
            ;;
    esac
fi