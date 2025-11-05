#!/bin/bash

# Portainer Management Script
# Manages Portainer system-level container

set -euo pipefail

# Get script directory and source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$TOOLKIT_ROOT/lib/common.sh"

CONTAINER_NAME="portainer"
PORTAINER_IMAGE="portainer/portainer-ce:latest"
VOLUME_NAME="portainer_data"

# Auto-confirm flag
AUTO_CONFIRM=false

# Check if Portainer container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Check if Portainer container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Start Portainer
start_portainer() {
    log "Starting Portainer..."
    
    if container_running; then
        success "Portainer is already running"
        return 0
    fi
    
    if container_exists; then
        log "Starting existing Portainer container..."
        docker start $CONTAINER_NAME
    else
        log "Creating and starting new Portainer container..."
        
        # Create volume if it doesn't exist
        if ! docker volume ls | grep -q $VOLUME_NAME; then
            log "Creating Portainer data volume..."
            docker volume create $VOLUME_NAME
        fi
        
        # Run Portainer container
        docker run -d \
            -p 8000:8000 \
            -p 9443:9443 \
            --name $CONTAINER_NAME \
            --restart=always \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v ${VOLUME_NAME}:/data \
            $PORTAINER_IMAGE
    fi
    
    # Wait for Portainer to be ready
    log "Waiting for Portainer to be ready..."
    for _ in {1..30}; do
        if curl -s -o /dev/null -w "%{http_code}" https://localhost:9443 | grep -q "200\|401\|302"; then
            success "Portainer is ready!"
            break
        fi
        sleep 2
    done
    
    success "Portainer started successfully"
    log "Access Portainer at: https://localhost:9443"
}

# Stop Portainer
stop_portainer() {
    log "Stopping Portainer..."
    
    if container_running; then
        docker stop $CONTAINER_NAME
        success "Portainer stopped"
    else
        warning "Portainer is not running"
    fi
}

# Remove Portainer completely
remove_portainer() {
    log "Removing Portainer..."
    
    if container_exists; then
        if container_running; then
            docker stop $CONTAINER_NAME
        fi
        docker rm $CONTAINER_NAME
        success "Portainer container removed"
    else
        warning "Portainer container does not exist"
    fi
    
    # Optionally remove volume
    if [[ "$AUTO_CONFIRM" == false ]]; then
        read -p "Remove Portainer data volume? (y/N): " remove_volume
        if [[ ! "$remove_volume" =~ ^[Yy]$ ]]; then
            return 0
        fi
    else
        log "Auto-confirm enabled: removing Portainer data volume..."
    fi
    
    docker volume rm $VOLUME_NAME 2>/dev/null || true
    success "Portainer data volume removed"
}

# Show Portainer status
show_status() {
    header "PORTAINER STATUS"
    
    if container_running; then
        success "Portainer is running"
        
        # Get container info
        local container_info
        local created
        local status
        container_info=$(docker inspect $CONTAINER_NAME --format "{{.Created}} {{.State.Status}}")
        created=$(echo "$container_info" | cut -d' ' -f1 | cut -d'T' -f1)
        status=$(echo "$container_info" | cut -d' ' -f2)
        
        echo "Container Status: $status"
        echo "Created: $created"
        echo "Image: $(docker inspect $CONTAINER_NAME --format "{{.Config.Image}}")"
        echo ""
        echo "Ports:"
        echo "  • Web UI (HTTPS): https://localhost:9443"
        echo "  • Edge Agent: http://localhost:8000"
        echo ""
        echo "Volume:"
        echo "  • Data: $VOLUME_NAME"
        
    elif container_exists; then
        warning "Portainer container exists but is not running"
    else
        error "Portainer container does not exist"
    fi
}

# Show Portainer logs
show_logs() {
    if container_exists; then
        log "Showing Portainer logs..."
        docker logs -f $CONTAINER_NAME
    else
        error "Portainer container does not exist"
    fi
}

# Update Portainer
update_portainer() {
    log "Updating Portainer..."
    
    # Pull latest image
    docker pull $PORTAINER_IMAGE
    
    if container_running; then
        log "Stopping Portainer for update..."
        docker stop $CONTAINER_NAME
    fi
    
    if container_exists; then
        log "Removing old container..."
        docker rm $CONTAINER_NAME
    fi
    
    log "Starting updated Portainer..."
    start_portainer
    
    success "Portainer updated successfully"
}

# Install Portainer (if not already installed)
install_portainer() {
    header "PORTAINER INSTALLATION"
    
    if container_exists; then
        success "Portainer is already installed"
        return 0
    fi
    
    log "Installing Portainer..."
    start_portainer
    success "Portainer installation completed"
}

# Show usage
show_usage() {
    echo "Usage: $0 {start|stop|restart|status|logs|install|update|remove} [-y|--yes]"
    echo ""
    echo "Commands:"
    echo "  start    - Start Portainer container"
    echo "  stop     - Stop Portainer container"
    echo "  restart  - Restart Portainer container"
    echo "  status   - Show Portainer status and access information"
    echo "  logs     - Show Portainer logs (follow mode)"
    echo "  install  - Install Portainer (first-time setup)"
    echo "  update   - Update Portainer to latest version"
    echo "  remove   - Remove Portainer container and optionally data"
    echo ""
    echo "Options:"
    echo "  -y, --yes   Auto-confirm all prompts (no user interaction)"
}

# Main command handling
case "${1:-}" in
    "start")
        start_portainer
        ;;
    "stop")
        stop_portainer
        ;;
    "restart")
        stop_portainer
        sleep 2
        start_portainer
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs
        ;;
    "install")
        install_portainer
        ;;
    "update")
        update_portainer
        ;;
    "remove")
        # Check for -y flag
        if [[ "${2:-}" == "-y" ]] || [[ "${2:-}" == "--yes" ]]; then
            AUTO_CONFIRM=true
        fi
        remove_portainer
        ;;
    "-y"|"--yes")
        # Support -y as first argument for any command
        AUTO_CONFIRM=true
        case "${2:-}" in
            "start") start_portainer ;;
            "stop") stop_portainer ;;
            "restart") stop_portainer; sleep 2; start_portainer ;;
            "status") show_status ;;
            "logs") show_logs ;;
            "install") install_portainer ;;
            "update") update_portainer ;;
            "remove") remove_portainer ;;
            *) show_usage; exit 1 ;;
        esac
        ;;
    *)
        show_usage
        exit 1
        ;;
esac