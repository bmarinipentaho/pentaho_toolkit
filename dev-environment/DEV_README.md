# Scripts Warehouse

Automated setup and management scripts for a Pentaho development environment on Ubuntu 22.04.

## What This Does

Sets up a complete development environment with:

- **PostgreSQL 15** with Pentaho databases (hibernate, quartz, jackrabbit) + data type testing
- **pgAdmin 4** web interface at http://localhost:8888
- **Portainer** Docker management at https://localhost:9443
- **Development tools** - git, Python, network utilities, modern CLI tools
- **Docker** + Docker Compose
- **Java versions** 8, 17, 21 with easy switching
- **LibWebKitGTK 1.0** for Pentaho UI tools (Spoon, Report Designer)

## Quick Start

```bash
# Complete automated setup
./scripts/setup/main.sh -y

# Interactive mode (prompts for confirmation)
./scripts/setup/main.sh
```

## Project Structure

```
scripts-warehouse/
├── scripts/
│   ├── setup/
│   │   ├── main.sh                          # Main setup script (start here)
│   │   ├── system/                          # System installations
│   │   │   ├── install-docker.sh
│   │   │   ├── install-dev-tools.sh
│   │   │   ├── install-vscode.sh
│   │   │   ├── install-github-cli.sh
│   │   │   └── configure-environment.sh
│   │   ├── docker/
│   │   │   └── postgres/                    # PostgreSQL Docker setup
│   │   │       ├── docker-compose.yml
│   │   │       ├── init-scripts/            # Database initialization
│   │   │       └── pgadmin-config/          # Pre-configured servers
│   │   └── pentaho/
│   │       └── install-pentaho-dependencies.sh
│   ├── manage/                              # Service management
│   │   ├── postgres.sh                      # PostgreSQL operations
│   │   └── portainer.sh                     # Portainer operations
│   ├── utils/
│   │   └── switch-java.sh                   # Java version switcher
│   └── lib/
│       └── common.sh                        # Shared functions
├── resources/
│   ├── packages/libwebkit/                  # LibWebKitGTK .deb files
│   └── configs/                             # Config templates
└── docs/
    └── DATA-TYPE-SHOWCASE.md                # Database schema docs
```

## Daily Usage

### Manage PostgreSQL

```bash
./scripts/manage/postgres.sh start           # Start PostgreSQL + pgAdmin
./scripts/manage/postgres.sh stop            # Stop services
./scripts/manage/postgres.sh status          # Check status
./scripts/manage/postgres.sh logs            # View logs
./scripts/manage/postgres.sh connect         # Connect to postgres db
./scripts/manage/postgres.sh connect hibernate hibuser  # Connect to specific db
```

### Manage Portainer

```bash
./scripts/manage/portainer.sh start
./scripts/manage/portainer.sh stop
./scripts/manage/portainer.sh status
```

### Switch Java Versions

```bash
./scripts/utils/switch-java.sh 8             # Java 8
./scripts/utils/switch-java.sh 17            # Java 17
./scripts/utils/switch-java.sh 21            # Java 21
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
- **Basics**: curl, wget, git, vim, nano, tree, mc, ncdu
- **Monitoring**: htop, glances, iotop, lsof, strace
- **Network**: nmap, tcpdump, netcat, mtr, dnsutils
- **Languages**: Python 3, pip, venv
- **Database Clients**: postgresql-client, mysql-client
- **Modern CLI**: fzf, bat, ripgrep (rg), fd-find, httpie, jq, xmlstarlet
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
