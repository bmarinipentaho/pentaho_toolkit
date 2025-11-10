#!/bin/bash
#
# Pentaho Minio Management Script
# Manages Minio S3-compatible object storage container
#

set -euo pipefail

# Get script directory and docker compose location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../setup/docker/minio"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source common functions from shared lib
source "$TOOLKIT_ROOT/lib/common.sh"

# Auto-confirm flag
AUTO_CONFIRM=false

# Check if Docker is available
check_docker() {
    if ! command_exists docker; then
        die "Docker is not installed. Please run the VM essentials setup script first."
    fi
    
    if ! check_docker_running; then
        die "Docker is not running. Please start Docker service."
    fi
    
    if ! command_exists docker-compose && ! docker compose version &> /dev/null; then
        die "Docker Compose is not available."
    fi
}

# Check container status
check_status() {
    log "Checking Minio container status..."
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "pentaho-minio"; then
        echo "Minio container is running:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pentaho-minio
        echo ""
        success "Minio is accessible at:"
        echo "  • S3 API:     http://localhost:19000"
        echo "  • Web Console: http://localhost:19001"
    else
        echo "Minio container is not running."
    fi
}

# Start services
start_services() {
    log "Starting Minio S3 storage..."
    
    cd "$DOCKER_DIR"
    
    # Check if .env exists, if not copy from template
    if [[ ! -f .env ]]; then
        log "Creating .env from template..."
        cp .env.template .env
        success "Created .env file - you can customize it as needed"
    fi
    
    # Start Minio
    log "Starting Minio server..."
    docker-compose up -d minio
    
    # Wait for Minio to be healthy
    log "Waiting for Minio to be ready..."
    timeout=60
    while [ $timeout -gt 0 ]; do
        if docker-compose ps minio | grep -q "healthy"; then
            break
        fi
        log "Minio starting... ($timeout seconds remaining)"
        sleep 5
        ((timeout-=5))
    done
    
    if [ $timeout -le 0 ]; then
        error "Minio failed to start within expected time"
        docker-compose logs minio
        return 1
    fi
    
    success "Minio is ready"
    
    # Run bucket initialization
    log "Initializing buckets..."
    docker-compose up minio-client
    
    success "All services started"
    echo ""
    log "Access Information:"
    echo "  • Web Console: http://localhost:19001"
    echo "  • S3 API:      http://localhost:19000"
    echo "  • Username:    admin"
    echo "  • Password:    password123"
    echo ""
    log "Pre-configured buckets:"
    echo "  • pentaho        (general storage)"
    echo "  • spark-logs     (Spark event logs)"
    echo "  • ael-artifacts  (AEL jars)"
}

# Stop services
stop_services() {
    log "Stopping Minio S3 storage..."
    cd "$DOCKER_DIR"
    docker-compose down
    success "Services stopped"
}

# Restart services
restart_services() {
    log "Restarting Minio S3 storage..."
    stop_services
    start_services
}

# Clean up everything
clean_services() {
    log "Cleaning up Minio S3 storage..."
    cd "$DOCKER_DIR"
    
    if [[ "$AUTO_CONFIRM" == false ]]; then
        warning "This will remove all containers, volumes, and stored objects!"
        read -p "Are you sure? (y/N): " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log "Cleanup cancelled"
            return 0
        fi
    else
        warning "Auto-confirm enabled: removing all containers, volumes, and data..."
    fi
    
    docker-compose down -v --remove-orphans
    docker-compose rm -f
    success "Cleanup completed"
}

# Show logs
show_logs() {
    cd "$DOCKER_DIR"
    if [ -n "${1:-}" ]; then
        docker-compose logs -f "$1"
    else
        docker-compose logs -f minio
    fi
}

# List buckets
list_buckets() {
    log "Listing Minio buckets..."
    docker exec pentaho-minio mc ls pentaho-minio || {
        warning "Unable to list buckets - Minio may not be running"
        return 1
    }
}

# Create bucket
create_bucket() {
    local bucket_name=$1
    log "Creating bucket: $bucket_name"
    docker exec pentaho-minio mc mb "pentaho-minio/$bucket_name" || {
        error "Failed to create bucket"
        return 1
    }
    success "Bucket created: $bucket_name"
}

# Display connection info
show_info() {
    echo ""
    log "Pentaho Minio S3 Storage Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📦 Minio S3-Compatible Object Storage"
    echo "  Web Console:    http://localhost:19001"
    echo "  S3 API:         http://localhost:19000"
    echo "  Root User:      admin"
    echo "  Root Password:  password123"
    echo ""
    echo "🪣 Pre-configured Buckets:"
    echo "  • pentaho        - General Pentaho data"
    echo "  • spark-logs     - Spark event logs"
    echo "  • ael-artifacts  - AEL jars and dependencies"
    echo ""
    echo "🔧 S3 Configuration (for applications):"
    echo "  Endpoint:       http://localhost:19000"
    echo "  Access Key:     admin"
    echo "  Secret Key:     password123"
    echo "  Region:         us-east-1 (default)"
    echo ""
    echo "💻 AWS CLI Usage:"
    echo "  aws --endpoint-url http://localhost:19000 s3 ls"
    echo "  aws --endpoint-url http://localhost:19000 s3 cp file.txt s3://pentaho/"
    echo ""
    echo "📁 Management:"
    echo "  List buckets:   $0 buckets"
    echo "  Create bucket:  $0 create-bucket <name>"
    echo "  Status:         $0 status"
    echo "  Logs:           $0 logs"
    echo ""
    echo "📚 Documentation:"
    echo "  $DOCKER_DIR/README.md"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Show help
show_help() {
    cat << EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Pentaho Minio S3 Storage Management
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Manage Minio S3-compatible object storage for Pentaho development.

USAGE:
    $0 <command> [options]

COMMANDS:
    start               Start Minio services
    stop                Stop Minio services
    restart             Restart Minio services
    status              Check Minio service status
    logs [service]      Show logs (default: minio)
    buckets             List all buckets
    create-bucket NAME  Create a new bucket
    info                Show connection information
    clean               Remove all containers and volumes (destructive!)
    help                Show this help message

OPTIONS:
    -y, --yes           Auto-confirm destructive operations

EXAMPLES:
    $0 start            # Start Minio
    $0 status           # Check if running
    $0 buckets          # List all buckets
    $0 create-bucket my-data  # Create new bucket
    $0 logs             # View Minio logs
    $0 clean -y         # Clean up (auto-confirm)

ACCESS:
    Web Console:  http://localhost:19001
    S3 API:       http://localhost:19000
    Credentials:  admin / password123

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            AUTO_CONFIRM=true
            export AUTO_CONFIRM
            shift
            ;;
        start|stop|restart|status|logs|buckets|create-bucket|info|clean|help)
            COMMAND=$1
            shift
            break
            ;;
        *)
            error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Default command
COMMAND=${COMMAND:-help}

# Execute command
case $COMMAND in
    start)
        check_docker
        start_services
        ;;
    stop)
        check_docker
        stop_services
        ;;
    restart)
        check_docker
        restart_services
        ;;
    status)
        check_docker
        check_status
        ;;
    logs)
        check_docker
        show_logs "${1:-}"
        ;;
    buckets)
        check_docker
        list_buckets
        ;;
    create-bucket)
        if [ -z "${1:-}" ]; then
            error "Bucket name required"
            echo "Usage: $0 create-bucket <bucket-name>"
            exit 1
        fi
        check_docker
        create_bucket "$1"
        ;;
    info)
        show_info
        ;;
    clean)
        check_docker
        clean_services
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac
