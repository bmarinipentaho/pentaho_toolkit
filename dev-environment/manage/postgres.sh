#!/bin/bash
# Pentaho PostgreSQL Management Script
set -euo pipefail

# Get script directory and docker compose location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$SCRIPT_DIR/../setup/docker/postgres"
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
    log "Checking PostgreSQL container status..."
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "pentaho-postgres"; then
        echo "PostgreSQL container is running:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pentaho-postgres
    else
        echo "PostgreSQL container is not running."
    fi
    
    if docker ps --format "table {{.Names}}\t{{.Status}}" | grep -q "pentaho-pgadmin"; then
        echo "pgAdmin container is running:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep pentaho-pgadmin
    else
        echo "pgAdmin container is not running."
    fi
}

# Start services
start_services() {
    log "Starting Pentaho PostgreSQL stack..."
    
    cd "$DOCKER_DIR"
    
    # Start PostgreSQL first
    log "Starting PostgreSQL..."
    docker-compose up -d postgres
    
    # Wait for PostgreSQL to be healthy
    log "Waiting for PostgreSQL to be ready..."
    timeout=120
    while [ $timeout -gt 0 ]; do
        if docker-compose ps postgres | grep -q "healthy"; then
            break
        fi
        log "PostgreSQL starting... ($timeout seconds remaining)"
        sleep 5
        ((timeout-=5))
    done
    
    if [ $timeout -le 0 ]; then
        error "PostgreSQL failed to start within expected time"
    fi
    
    success "PostgreSQL is ready"
    
    # Start pgAdmin
    log "Starting pgAdmin..."
    docker-compose up -d pgadmin
    
        success "All services started"
    
    # Wait a moment for pgAdmin to fully start
    log "Waiting for pgAdmin to be ready..."
    sleep 5
    
    success "All services started"
}

# Stop services
stop_services() {
    log "Stopping Pentaho PostgreSQL stack..."
    cd "$DOCKER_DIR"
    docker-compose down
    success "Services stopped"
}

# Restart services
restart_services() {
    log "Restarting Pentaho PostgreSQL stack..."
    stop_services
    start_services
}

# Clean up everything
clean_services() {
    log "Cleaning up Pentaho PostgreSQL stack..."
    cd "$DOCKER_DIR"
    
    if [[ "$AUTO_CONFIRM" == false ]]; then
        warning "This will remove all containers, volumes, and data!"
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
    if [ -n "$1" ]; then
        docker-compose logs -f "$1"
    else
        docker-compose logs -f
    fi
}

# Connect to database
connect_db() {
    local db=${1:-hibernate}
    local user=${2:-hibuser}
    
    log "Connecting to database '$db' as user '$user'..."
    docker exec -it pentaho-postgres psql -U "$user" -d "$db"
}

# Display connection info
show_info() {
    echo ""
    log "Pentaho PostgreSQL Connection Information:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "PostgreSQL Server:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo ""
    echo "Databases:"
    echo "  hibernate         - hibuser/password         (Main Pentaho repository)"
    echo "  quartz            - pentaho_user/password    (Job scheduler)"
    echo "  jackrabbit        - jcr_user/password        (Content repository)"
    echo "  🎯 data_type_showcase - datatype_user/datatype_user (Data type testing)"
    echo "  postgres          - postgres/postgres        (Admin database)"
    echo ""
    echo "pgAdmin Web Interface:"
    echo "  🌐 URL: http://localhost:8888"
    echo "  👤 Login: admin@pentaho.com"
    echo "  🔑 Password: admin"
    echo "  📝 Note: All Pentaho databases are pre-configured!"
    echo ""
    echo "🚀 Quick Start:"
    echo "  1. Open http://localhost:8888 in your browser"
    echo "  2. Login with admin@pentaho.com / admin" 
    echo "  3. Expand 'Pentaho Databases' in the left panel"
    echo "  4. All databases are ready to use!"
    echo ""
    echo "Quick Commands:"
    echo "  Status:    $0 status"
    echo "  Logs:      $0 logs [service]"
    echo "  Connect:   $0 connect [database] [user]"
    echo "  Stop:      $0 stop"
    echo "  Restart:   $0 restart"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main execution
main() {
    log "Pentaho PostgreSQL Management"
    check_docker
    start_services
    show_info
}

# Handle script arguments
case "${1:-}" in
    "start")
        check_docker
        start_services
        show_info
        ;;
    "stop")
        stop_services
        ;;
    "restart")
        check_docker
        restart_services
        show_info
        ;;
    "status")
        check_status
        ;;
    "logs")
        show_logs "${2:-}"
        ;;
    "connect")
        connect_db "${2:-hibernate}" "${3:-hibuser}"
        ;;
    "clean")
        # Check for -y flag
        if [[ "${2:-}" == "-y" ]] || [[ "${2:-}" == "--yes" ]]; then
            AUTO_CONFIRM=true
        fi
        clean_services
        ;;
    "-y"|"--yes")
        # Support -y as first argument for any command
        AUTO_CONFIRM=true
        case "${2:-}" in
            "start")
                check_docker
                start_services
                show_info
                ;;
            "clean")
                clean_services
                ;;
            *)
                main
                ;;
        esac
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "info")
        show_info
        ;;
    *)
        main
        ;;
esac