# Development Environment Setup

Automated setup and management scripts for a Pentaho development environment on Ubuntu 22.04.

## What This Does

Sets up a complete development environment with:

- **PostgreSQL 15** with Pentaho databases (hibernate, quartz, jackrabbit) + data type testing
- **pgAdmin 4** web interface at http://localhost:8888
- **Portainer** Docker management at https://localhost:9443
- **Development tools** - git, Python, network utilities, modern CLI tools (jq, xmlstarlet, tmux, fzf)
- **Docker** + Docker Compose
- **Java versions** 8, 17, 21 with easy switching
- **LibWebKitGTK 1.0** for Pentaho UI tools (Spoon, Report Designer)
- **Text editors** - VS Code, gedit, vim, nano

## Quick Start

```bash
# Complete automated setup
./dev-environment/setup/main.sh -y

# Interactive mode (prompts for confirmation)
./dev-environment/setup/main.sh
```

## Project Structure

```
dev-environment/
├── setup/
│   ├── main.sh                              # Main setup script (start here)
│   ├── system/                              # System installations
│   │   ├── install-docker.sh
│   │   ├── install-dev-tools.sh
│   │   ├── install-vscode.sh
│   │   ├── install-github-cli.sh
│   │   └── configure-environment.sh
│   ├── docker/
│   │   ├── postgres/                        # PostgreSQL Docker setup
│   │   │   ├── docker-compose.yml
│   │   │   ├── init-scripts/                # Database initialization
│   │   │   └── pgadmin-config/              # Pre-configured servers
│   │   └── minio/                           # Minio S3 setup
│   │       └── docker-compose.yml
│   └── pentaho/
│       └── install-pentaho-dependencies.sh
├── manage/                                  # Service management
│   ├── postgres.sh                          # PostgreSQL operations
│   ├── minio.sh                             # Minio S3 operations
│   └── portainer.sh                         # Portainer operations
├── utils/
│   └── switch-java.sh                       # Java version switcher
└── resources/
    └── packages/libwebkit/                  # LibWebKitGTK .deb files
```

## Daily Usage

### Manage PostgreSQL

```bash
./dev-environment/manage/postgres.sh start           # Start PostgreSQL + pgAdmin
./dev-environment/manage/postgres.sh stop            # Stop services
./dev-environment/manage/postgres.sh status          # Check status
./dev-environment/manage/postgres.sh logs            # View logs
./dev-environment/manage/postgres.sh connect         # Connect to postgres db
./dev-environment/manage/postgres.sh connect hibernate hibuser  # Connect to specific db
```

### Manage Minio

```bash
./dev-environment/manage/minio.sh start              # Start Minio S3
./dev-environment/manage/minio.sh stop               # Stop Minio
./dev-environment/manage/minio.sh status             # Check status
./dev-environment/manage/minio.sh buckets            # List buckets
```

### Manage Portainer

```bash
./dev-environment/manage/portainer.sh start
./dev-environment/manage/portainer.sh stop
./dev-environment/manage/portainer.sh status
```

### Switch Java Versions

```bash
./dev-environment/utils/switch-java.sh 8             # Java 8
./dev-environment/utils/switch-java.sh 17            # Java 17
./dev-environment/utils/switch-java.sh 21            # Java 21
```

## Access Information

| Service | Address | Username | Password |
|---------|---------|----------|----------|
| pgAdmin | http://localhost:8888 | admin@pentaho.com | admin |
| Portainer | https://localhost:9443 | (create on first login) | - |
| PostgreSQL | localhost:5432 | see table below | - |

### PostgreSQL Databases

| Database | User | Password | Purpose |
|----------|------|----------|---------|
| hibernate | hibuser | password | Pentaho repository |
| quartz | pentaho_user | password | Scheduler |
| jackrabbit | jcr_user | password | Content repository |
| data_type_showcase | datatype_user | datatype_user | Testing all PostgreSQL types |
| postgres | postgres | postgres | Admin |

## Components Installed

### Development Tools
- **Text Editors**: gedit (GUI), vim, nano
- **Basics**: curl, wget, git, tree, mc, ncdu
- **Monitoring**: htop, glances, iotop, lsof, strace
- **Network**: nmap, tcpdump, netcat, mtr, dnsutils
- **Languages**: Python 3, pip, venv
- **Database Clients**: postgresql-client, mysql-client
- **Modern CLI Tools**:
  - `jq` - JSON parsing and manipulation
  - `yq` - YAML parsing and manipulation
  - `xmlstarlet` - XML parsing and transformation
  - `fzf` - Fuzzy finder for files and commands
  - `tmux` - Terminal multiplexer (persistent sessions)
  - `pv` - Pipe viewer (progress monitoring)
  - `parallel` - GNU parallel for batch operations
  - `ag` (silversearcher) - Fast code search
  - `bat` - cat with syntax highlighting
  - `ripgrep` (rg) - Fast grep alternative
  - `fd-find` - Fast find alternative
  - `httpie` - User-friendly HTTP client
- **Security**: Kerberos client, OpenSSL

### Environment Setup

**Directories**:
- `~/pentaho/` - Main workspace
- `~/pentaho/configs/` - Configuration files
- `~/pentaho/keytabs/` - Kerberos keytabs
- `~/pentaho/certs/` - SSL certificates
- `~/pentaho/logs/` - Logs
- `~/pentaho/scripts/` - Custom scripts

**Variables** (added to `~/.bashrc`):
```bash
export PENTAHO_HOME=~/pentaho
export PENTAHO_JAVA_HOME=$JAVA_HOME
export KRB5_CONFIG=/etc/krb5.conf
```

**Aliases**:
- `ls` → `eza` (modern ls)
- `cat` → `bat` (syntax highlighting)
- `find` → `fd` (faster find)
- `grep` → `rg` (ripgrep)
- `docker-clean` - Clean Docker resources
- `docker-stop-all` - Stop all containers
- `pentaho-logs` - cd to ~/pentaho/logs
- `pentaho-configs` - cd to ~/pentaho/configs

## Run Individual Components

```bash
# Just Docker
./scripts/setup/system/install-docker.sh

# Just dev tools
./scripts/setup/system/install-dev-tools.sh

# Just environment config
./scripts/setup/system/configure-environment.sh

# Just PostgreSQL
./scripts/manage/postgres.sh start

# Just Pentaho UI dependencies
./scripts/setup/pentaho/install-pentaho-dependencies.sh
```

## Troubleshooting

### Accessing Web UIs from Host Machine

If running in a VM and want to access web consoles from your host machine (Windows/Mac):

**VirtualBox Port Forwarding:**
1. VM Settings → Network → Adapter 1 → Advanced → Port Forwarding
2. Add rules:
   - **pgAdmin:** Host Port 8888 → Guest Port 8888
   - **Minio Console:** Host Port 19001 → Guest Port 9001
   - **Minio API:** Host Port 19000 → Guest Port 9000
   - **Portainer:** Host Port 9443 → Guest Port 9443
   - **PostgreSQL:** Host Port 5432 → Guest Port 5432 (optional)

Then access from host browser using `http://localhost:8888`, etc.

**Note:** PDI running inside the VM uses localhost connections - no special config needed.

### Docker permission denied

```bash
newgrp docker                                # Activate docker group (temporary)
# OR logout and login (permanent)
```

### PostgreSQL won't start

```bash
./scripts/manage/postgres.sh logs postgres  # Check logs
docker rm -f pentaho-postgres pentaho-pgadmin  # Remove old containers
./scripts/manage/postgres.sh start          # Restart
```

### Can't connect to pgAdmin

1. Check PostgreSQL is running: `./scripts/manage/postgres.sh status`
2. Check logs: `./scripts/manage/postgres.sh logs pgadmin`
3. Servers are pre-configured under "Pentaho Databases" group in pgAdmin UI

## Requirements

- Ubuntu 22.04 LTS
- Non-root user with sudo privileges
- ~10GB free disk space
- Internet connection

## CLI Tools Usage Examples

### JSON/XML Parsing
```bash
# Parse JSON output from Pentaho API
curl http://localhost:8080/pentaho/api/repos | jq '.children[] | .name'

# Modify Pentaho XML config
xmlstarlet ed -u "//param[@name='url']/@value" -v "jdbc:postgresql://localhost:5432/hibernate" repository.xml

# Parse YAML config
yq '.version' config.yaml
```

### File Search & Navigation
```bash
# Fuzzy find files (opens interactive selector)
fzf

# Search code (faster than grep)
ag "className" ~/pentaho/
rg "function.*transform" --type java

# Find files by name
fd "*.ktr" ~/pentaho/
```

### Terminal Management
```bash
# Start tmux session
tmux new -s pentaho

# Detach: Ctrl+B, then D
# Reattach: tmux attach -t pentaho
# List sessions: tmux ls
```

### Progress Monitoring
```bash
# Monitor file copy progress
pv large-file.zip | unzip -

# Monitor database restore
pv database-dump.sql | psql -U postgres

# Batch operations with progress
find . -name "*.log" | parallel gzip {}
```

### Quick File Viewing
```bash
# Quick look at config file
gedit ~/pentaho/configs/kettle.properties &

# View with syntax highlighting
bat ~/pentaho/configs/repository.xml

# HTTP requests
http GET http://localhost:8080/pentaho/api/version
```

## Data Type Testing

The `data_type_showcase` database includes examples of all PostgreSQL data types:
- Numeric (integer, decimal, serial)
- Character (varchar, text, char)
- Date/time (timestamp, date, interval)
- Boolean, UUID, JSON/JSONB
- Geometric (point, line, polygon)
- Network (inet, cidr, macaddr)
- Binary (bytea)
- Arrays

See `docs/DATA-TYPE-SHOWCASE.md` for details.

## Resources

- [Pentaho Documentation](https://help.hitachivantara.com/Documentation/Pentaho)
- [PostgreSQL 15 Docs](https://www.postgresql.org/docs/15/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

**Tested on**: Ubuntu 22.04 LTS (Jammy Jellyfish)  
**Last updated**: November 2025
