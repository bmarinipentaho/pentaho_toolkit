# Pentaho Toolkit

Automated setup and management for Pentaho development environments. Install PDI, configure data platforms (Hadoop/Spark), and manage databases with one command.

## Quick Start

```bash
# Clone and setup
git clone https://github.com/bmarinipentaho/pentaho_toolkit.git
cd pentaho_toolkit

# Full dev environment (Docker, PostgreSQL, Minio, Hadoop, Spark)
./dev-environment/setup/main.sh

# Or install components individually:
./data-platform/install.sh              # Hadoop 3.4.1 + Spark 4.0.0
./pentaho/pdi/install-pdi.sh <zip>      # PDI with license automation
./pentaho/server/install-server.sh      # Server with auto-plugin discovery
./dev-environment/manage/postgres.sh start   # PostgreSQL + pgAdmin
./dev-environment/manage/minio.sh start      # S3 storage
```

## What's Included

### 🛠️ Development Environment
Complete setup for Pentaho development on Ubuntu 22.04:
- **Java 21** (OpenJDK)
- **Docker & Compose** with Portainer UI
- **PostgreSQL** - Pre-configured with Pentaho schemas (hibernate, quartz, jackrabbit, logging)
- **Minio S3** - Object storage with auto-created buckets (pentaho, spark-logs, ael-artifacts)
- **Dev Tools** - Git, curl, VSCode, GitHub CLI

**Access:**
- pgAdmin: http://localhost:8888 (admin@pentaho.com / admin)
- Minio Console: http://localhost:9001 (admin / password123)
- Portainer: https://localhost:9443

### 📦 Data Platform (Hadoop + Spark)
Native installations for big data processing:
- **Hadoop 3.4.1** - HDFS and YARN (~1.7GB)
- **Spark 4.0.0** - Distributed computation with AEL support (~577MB)
- Version management with symlinks (hadoop-current, spark-current)
- Smart archive.apache.org fallback for historical versions

### 🔧 Pentaho Components
- **PDI Installer** - Support for `{version}/{build}/pdi/` directory structure
- **Server Installer** - Auto-discovery of server + plugins, version validation, PostgreSQL config
- **License Automation** - Auto-install licenses from flexnet URLs
- **Project Profiles** - Centralized kettle.properties and metastore
- **Cleanup Scripts** - Remove installations, caches, temp files

### ⚡ AEL (Adaptive Execution Layer)
*Being rebuilt with modular architecture*
- Requires: PDI + Hadoop + Spark
- See `ael/README.md` for current status

## Repository Structure

```
pentaho_toolkit/
├── lib/common.sh                             # Shared logging, validation, error handling
│
├── dev-environment/                          # Complete dev environment setup
│   ├── setup/main.sh                         # Main installer (all components)
│   ├── manage/{postgres,minio,portainer}.sh  # Service management
│   └── setup/docker/{postgres,minio}/        # Container configurations
│
├── data-platform/                            # Hadoop + Spark installers
│   ├── install.sh                            # Master installer
│   ├── cleanup.sh                            # Remove all installations
│   ├── hadoop/install-hadoop.sh              # Hadoop 3.4.1
│   └── spark/install-spark.sh                # Spark 4.0.0
│
├── pentaho/                                  # Pentaho components
│   ├── pdi/install-pdi.sh                    # PDI installer with license automation
│   ├── server/install-server.sh              # Server installer with plugin discovery
│   ├── server/configure-server.sh            # PostgreSQL configuration
│   ├── server/manage-server.sh               # Server lifecycle (start/stop/status)
│   └── cleanup.sh                            # Remove all Pentaho installations
│
└── ael/                                      # AEL (being rebuilt)
```

## Common Management Tasks

```bash
# Service management
./dev-environment/manage/postgres.sh [start|stop|status|logs|connect]
./dev-environment/manage/minio.sh [start|stop|status|buckets]
./dev-environment/manage/portainer.sh [start|stop|status]
./pentaho/server/manage-server.sh [start|stop|restart|status|logs|karaf|clean]

# Cleanup
./data-platform/cleanup.sh                    # Remove Hadoop/Spark
./pentaho/cleanup.sh [--pdi-only|--server-only|--all]  # Remove Pentaho installations

# Installation paths
~/data-platform/installs/hadoop-current -> hadoop-3.4.1/
~/data-platform/installs/spark-current  -> spark-4.0.0/
~/pentaho/{version}/{build}/pdi/data-integration/
~/pentaho/{version}/{build}/server/pentaho-server/
~/pentaho/{version}/{build}/server-current -> pentaho-server/
```

## Documentation

Each module has detailed docs:
- **[Dev Environment](dev-environment/DEV_README.md)** - Full setup guide, troubleshooting
- **[Data Platform](data-platform/README.md)** - Hadoop/Spark installation, S3 integration
- **[Pentaho/PDI](pentaho/README.md)** - PDI installer, license automation
- **[AEL](ael/README.md)** - AEL setup and architecture

## Prerequisites

- Ubuntu 22.04 or later
- Sudo access
- Internet connection
- ~20GB free disk space

Scripts will install most dependencies automatically.

## Troubleshooting

```bash
# Scripts not executable
chmod -R +x .

# Docker permission errors
sudo usermod -aG docker $USER
newgrp docker

# Port conflicts
sudo lsof -i :8080
```

**AEL-specific issues:** See `ael/AEL_TROUBLESHOOTING_AND_CONTAINERIZATION_SUMMARY.md`

## Development Status

| Component | Status | Notes |
|-----------|--------|-------|
| Dev Environment | ✅ Complete | PostgreSQL, Minio, Docker, Java |
| Data Platform | ✅ Complete | Hadoop 3.4.1, Spark 4.0.0 |
| PDI Installer | ✅ Complete | License automation, profiles |
| Server Installer | ✅ Complete | Plugin discovery, version validation, management |
| AEL | 🔄 In Progress | Rebuilding with modular design |

## Origin

Consolidates and improves:
- `ael-automation` - Internal AEL deployment scripts
- `scripts-warehouse` - Dev environment automation

---

**License:** Internal use for Pentaho/Hitachi Vantara QA  
**Support:** Open an issue on GitHub
