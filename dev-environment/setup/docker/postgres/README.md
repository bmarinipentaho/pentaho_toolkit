# Pentaho PostgreSQL Docker Setup

Complete PostgreSQL setup for Pentaho Server with pgAdmin web interface.

## Structure

```
postgres/
├── docker-compose.yml           # PostgreSQL + pgAdmin orchestration
├── Dockerfile                   # PostgreSQL container
├── manage-postgres.sh          # Management script
├── init-scripts/               # SQL initialization (runs in order)
│   ├── 01-create_repository_postgresql.sql
│   ├── 02-create_quartz_postgresql.sql  
│   ├── 03-create_jcr_postgresql.sql
│   ├── 04-pentaho_logging_postgresql.sql
│   ├── 05-pentaho_mart_postgresql.sql
│   ├── 06-data-type-showcase.sql      # Comprehensive data type testing
│   └── 99-verify-setup.sql
├── pgadmin-config/             # pgAdmin pre-configuration
│   ├── servers.json           # Pre-configured connections
│   └── pgpass                 # Stored passwords
└── postgresql/                # Original Pentaho SQL files
```

## Prerequisites

```bash
# Install Docker and Docker Compose (ignore any GPG key warnings)
sudo apt update
sudo apt install -y docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Log out and back in, or run:
newgrp docker

# Verify installation
docker --version
docker-compose --version || docker compose version
```

**Note**: If `docker-compose` command is not found, run:
```bash
sudo apt install -y docker-compose
```

Or use the newer `docker compose` (without hyphen) command which is built into modern Docker.

## Quick Start

```bash
# Start the PostgreSQL stack
./manage-postgres.sh

# Or use specific commands
./manage-postgres.sh start
./manage-postgres.sh status
./manage-postgres.sh logs
./manage-postgres.sh stop
```

## What Gets Created

### Databases
- **hibernate** - Main Pentaho repository (hibuser/password)
- **quartz** - Job scheduler database (pentaho_user/password) 
- **jackrabbit** - Content repository (jcr_user/password)
- **pentaho_logging** - Application logging (logging_user/password)
- **pentaho_mart** - Data mart (mart_user/password)
- **data_type_showcase** - Comprehensive data type testing (datatype_user/datatype_user)

### Schemas
- **pentaho_dilogs** - ETL job logging tables
- **pentaho_operations_mart** - Operational analytics tables

## Access Points

### PostgreSQL
- **Host**: localhost:5432 (or VM_IP:5432 for external access)
- **Admin**: postgres/postgres
- **Main repo**: hibuser/password on hibernate database

### pgAdmin Web Interface  
- **URL**: http://localhost:8888 (or http://VM_IP:8888 for external access)
- **Login**: admin@pentaho.com / admin
- **Pre-configured connections** to all Pentaho databases

### External Access (from other machines/OS)
- **PostgreSQL**: `VM_IP:5432` (replace VM_IP with your VM's IP address)
- **pgAdmin**: `http://VM_IP:8888`
- **Firewall**: Ensure ports 5432 and 8888 are open on the VM

## Management Commands

```bash
./manage-postgres.sh start      # Start services
./manage-postgres.sh stop       # Stop services  
./manage-postgres.sh restart    # Restart services
./manage-postgres.sh status     # Check status
./manage-postgres.sh logs       # View logs
./manage-postgres.sh logs postgres  # View specific service logs
./manage-postgres.sh connect    # Connect to hibernate DB
./manage-postgres.sh connect quartz pentaho_user  # Connect to specific DB
./manage-postgres.sh clean      # Remove all data (with confirmation)
./manage-postgres.sh info       # Show connection information
```

## External Access Configuration

### For Pentaho Builds on Different Machines/OS

**✅ Already Configured!** The setup automatically exposes PostgreSQL for external access.

#### Get Your VM's IP Address:
```bash
# Find your VM's IP address
ip addr show | grep inet | grep -v 127.0.0.1 | grep -v ::1
# Or simply:
hostname -I
```

#### Configure Firewall (if needed):
```bash
# Ubuntu/Debian
sudo ufw allow 5432/tcp  # PostgreSQL
sudo ufw allow 8888/tcp  # pgAdmin

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --permanent --add-port=8888/tcp
sudo firewall-cmd --reload
```

#### Connection Examples:
```bash
# From Windows Pentaho (replace 192.168.1.100 with your VM IP)
Host: 192.168.1.100
Port: 5432
Database: hibernate
Username: hibuser
Password: password

# JDBC URL for Pentaho:
jdbc:postgresql://192.168.1.100:5432/hibernate

# Data Type Showcase Database:
jdbc:postgresql://192.168.1.100:5432/data_type_showcase
Username: datatype_user
Password: datatype_user
```

## Features

✅ **Automated Setup** - Runs all Pentaho SQL scripts in correct order  
✅ **Health Checks** - Waits for PostgreSQL to be ready before starting pgAdmin  
✅ **Pre-configured pgAdmin** - All databases accessible immediately  
✅ **Persistent Data** - Data survives container restarts  
✅ **Smart Management** - Check status, rebuild if needed  
✅ **Complete Isolation** - Dedicated network, no conflicts  
✅ **External Access Ready** - Connect from any machine or OS  

## Troubleshooting

```bash
# View setup logs
./manage-postgres.sh logs postgres | grep -A5 -B5 "ERROR\|WARNING"

# Connect directly to check tables
./manage-postgres.sh connect hibernate hibuser
\dt pentaho_dilogs.*
\dt pentaho_operations_mart.*

# Reset everything if needed
./manage-postgres.sh clean
./manage-postgres.sh start
```