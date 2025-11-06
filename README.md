# Pentaho Toolkit

A comprehensive collection of automation scripts and tools for Pentaho development, testing, and deployment. Designed for QA engineers and developers working with Pentaho Data Integration (PDI) and AEL (Adaptive Execution Layer).

## Overview

This toolkit consolidates two main areas:
- **AEL Environment Setup** - Automated deployment of Hadoop, Spark, and AEL for testing PDI transformations
- **Development Environment** - Setup scripts for Docker, PostgreSQL, Pentaho dependencies, and development tools

## Quick Start

```bash
# Clone the repository
git clone https://github.com/bmarinipentaho/pentaho_toolkit.git
cd pentaho_toolkit

# Make all scripts executable
chmod -R +x .

# Choose your path:
# 1. Set up AEL environment
cd ael
./deploy_ael.sh --help

# 2. Set up development environment
cd dev-environment
./setup/main.sh
```

## Repository Structure

```
pentaho_toolkit/
├── lib/                                      # Shared utilities
│   └── common.sh                             # Common functions, logging, validation
│
├── dev-environment/                          # Development environment setup
│   ├── setup/                                # Installation scripts
│   │   ├── main.sh                           # Main setup orchestrator
│   │   ├── system/                           # System-level installers
│   │   │   ├── install-java.sh               # Java 21 (OpenJDK)
│   │   │   ├── install-docker.sh             # Docker & Docker Compose
│   │   │   ├── install-dev-tools.sh          # Build essentials, git, curl
│   │   │   └── ...                           # VSCode, GitHub CLI, environment config
│   │   ├── docker/                           # Docker service configurations
│   │   │   ├── postgres/                     # PostgreSQL + pgAdmin
│   │   │   └── minio/                        # Minio S3 storage
│   │   └── pentaho/                          # Pentaho dependencies (libwebkit)
│   ├── manage/                               # Management utilities
│   │   ├── postgres.sh                       # PostgreSQL operations
│   │   ├── minio.sh                          # Minio S3 storage operations
│   │   └── portainer.sh                      # Portainer management
│   ├── docs/                                 # Documentation
│   ├── resources/                            # Package files and configs
│   └── utils/                                # Utility scripts
│
├── pentaho/                                  # Pentaho installation tools
│   ├── pdi/                                  # PDI installer with license automation
│   ├── cleanup.sh                            # Cleanup script for all Pentaho components
│   └── README.md                             # Pentaho module documentation
│
├── data-platform/                            # Big data components
│   ├── install.sh                            # Master installer for Hadoop + Spark
│   ├── cleanup.sh                            # Remove all data platform installations
│   ├── hadoop/                               # Hadoop HDFS & YARN
│   │   └── install-hadoop.sh                 # Hadoop 3.4.1 installer
│   ├── spark/                                # Apache Spark
│   │   └── install-spark.sh                  # Spark 4.0.0 installer
│   └── README.md                             # Data platform documentation
│
├── ael/                                      # AEL Spark execution (being rebuilt)
│   ├── [Old scripts]                         # Original ael-automation files
│   └── README.md                             # New modular design documentation
│
├── workflows/                                # End-to-end orchestrators (coming soon)
│   └── README.md                             # Workflow documentation
│
└── docs/                                     # General documentation
```

## What's Inside

### Development Environment (`dev-environment/`)

Tools for setting up a complete Pentaho development environment:

- **Java 21** - OpenJDK automatically installed and configured
- **Docker & Docker Compose** - Container runtime
- **PostgreSQL** - With Pentaho databases pre-configured
  - Repository, Quartz, JCR, Logging, Data Mart schemas
  - pgAdmin for database management
- **Minio S3 Storage** - S3-compatible object storage for data and artifacts
- **Portainer** - Docker container management UI
- **System Tools** - VSCode, GitHub CLI, dev utilities
- **Pentaho Dependencies** - Libraries and packages required for PDI

**Shared Library:** All scripts source `lib/common.sh` for consistent logging, error handling, and validation.

📖 **[Full Dev Environment Documentation](dev-environment/DEV_README.md)**

---

### Pentaho Platform (`pentaho/`)

PDI installation and cleanup tools with automated license installation:

- **PDI Installer** - Install from local zips with `{version}/{build}/pdi/` structure
- **License Automation** - Automatic license installation from flexnet URL
- **Cleanup Script** - Remove all PDI installations, caches, and temp files
- **Parallel Installations** - Multiple versions and builds can coexist
- **Project Profiles** - Support for centralized kettle properties and metastore
- **Complete Extraction** - Includes data-integration, license-installer, jdbc-distribution

📖 **[Pentaho Module Documentation](pentaho/README.md)**

---

### Data Platform (`data-platform/`)

Big data infrastructure for AEL and distributed transformations:

- **Hadoop 3.4.1** - HDFS and YARN for distributed storage and processing
- **Spark 4.0.0** - Distributed computation engine with AEL support
- **Version Management** - Multiple parallel installations supported
- **Master Installer** - One command to install both components
- **Cleanup Script** - Remove all installations, data, and temp files
- **Native Installation** - Optimized for performance (not containerized)

**Key Features:**
- Downloads from Apache archives (stable, historical versions)
- Smart version detection for Spark 3.x vs 4.x naming
- Symlinks for easy version switching
- Integrated with main dev environment setup

📖 **[Data Platform Documentation](data-platform/README.md)**

---

### AEL - Adaptive Execution Layer (`ael/`) - Being Rebuilt

Pentaho Spark execution addon for distributed transformations:

- **Current:** Original ael-automation scripts (functional but legacy)
- **Future:** Rebuilt with modular design, proper validation, and modern practices
- **Dependencies:** Requires `pentaho/pdi/`, `data-platform/hadoop/`, and `data-platform/spark/`

📖 **[AEL Documentation](ael/README.md)** | **[Old AEL README](ael/AEL_README.md)**

---

### Workflows (`workflows/`) - Coming Soon

End-to-end orchestration scripts for common scenarios:

- `setup-development.sh` - Dev tools only
- `setup-basic-pentaho.sh` - PostgreSQL + Pentaho Server + PDI
- `setup-ael-environment.sh` - Complete AEL testing environment

📖 **[Workflow Documentation](workflows/README.md)**

---

## Shared Libraries

Common utilities used across all modules:

- **Logging framework** - Colored output with log levels (log, success, error, warning)
- **Validation functions** - Input validation, prerequisite checks
- **Service management** - Health checks, port monitoring
- **Error handling** - Standardized error reporting with `die()` function

**Location:** `lib/common.sh` - All scripts source this for consistency.

## Use Cases

### 1. Setting Up a New Development VM
```bash
cd dev-environment/setup
./main.sh
# Installs Docker, PostgreSQL, Minio, Hadoop, Spark, VSCode, and dev tools
```

### 2. Installing Just the Data Platform
```bash
cd data-platform
./install.sh
# Installs Hadoop 3.4.1 and Spark 4.0.0
```

### 3. Database Management
```bash
cd dev-environment/manage
./postgres.sh start
# Access pgAdmin at http://localhost:8888
```

### 4. S3 Storage Management
```bash
cd dev-environment/manage
./minio.sh start
# Access Minio console at http://localhost:9001
./minio.sh buckets  # List buckets
```

### 5. Installing Pentaho PDI
```bash
cd pentaho/pdi
./install-pdi.sh /path/to/pdi-9.4.0.0-343.zip
# Or with license automation:
./install-pdi.sh /path/to/pdi.zip --license-url "https://flexnet.example.com/licenses"
```

## Target Environment

**Designed for:** Ubuntu 22.04/24.04 (Valhalla VMs)

While these scripts are optimized for Ubuntu-based VMs, most components should work on other Linux distributions with minor modifications.

## Prerequisites

Minimal requirements (scripts will install most dependencies):
- Ubuntu 22.04 or later
- Sudo access
- Internet connection for downloads
- ~20GB free disk space (for AEL setup)

## Contributing

This is a personal QA toolkit. Improvements, bug fixes, and suggestions are welcome!

### Common Tasks

**Update shared library:**
```bash
# Edit shared/lib/common.sh
# Update scripts to source it:
source "$(dirname "$0")/../../shared/lib/common.sh"
```

**Add new dev tool:**
```bash
# Create script in dev-environment/setup/system/
# Add to main.sh orchestrator
```

## Troubleshooting

### AEL Issues
- See `ael/AEL_TROUBLESHOOTING_AND_CONTAINERIZATION_SUMMARY.md`
- Check cluster connectivity: `ael/cluster_context.md`

### Common Problems

**Scripts not executable:**
```bash
chmod -R +x .
```

**Permission errors:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

**Port conflicts:**
```bash
# Check what's using a port
sudo lsof -i :8080
```

## Roadmap

### Phase 1: Dev Environment ✅
- [x] Consolidate repositories into unified structure
- [x] Migrate all scripts to shared logging library
- [x] Remove redundant code and improve error handling
- [x] Create modular directory structure
- [x] PostgreSQL with Pentaho schemas
- [x] Minio S3 object storage
- [x] Portainer container management

### Phase 2: Data Platform ✅
- [x] Hadoop 3.4.1 installer
- [x] Spark 4.0.0 installer (archive.apache.org support)
- [x] Master installer for both components
- [x] Cleanup script for installations
- [x] Integration with dev environment setup
- [x] Comprehensive documentation

### Phase 3: Pentaho Platform ✅
- [x] PDI installation with license automation
- [x] Support for version/build directory structure
- [x] Project profiles and metastore support
- [x] Cleanup scripts
- [ ] Pentaho Server installation (planned)
- [ ] Server configuration automation (planned)

### Phase 4: AEL Rebuild (Next)
- [ ] Rebuild AEL addon installer with modern practices
- [ ] Configuration management improvements
- [ ] Local and YARN mode support
- [ ] Integration with modular data platform
- [ ] Validation and verification scripts

### Phase 5: Testing & Documentation
- [ ] Automated smoke tests for each module
- [ ] CI/CD pipeline with shellcheck
- [ ] Comprehensive troubleshooting guides
- [ ] Video walkthroughs

### Future Enhancements
- [ ] Docker containerization for full stack
- [ ] Multi-node cluster support
- [ ] Automated backup and restore
- [ ] Performance optimization guides

## Origin

This toolkit consolidates and improves upon:
- `ael-automation` - Originally developed by a team developer for internal use
- `scripts-warehouse` - Personal collection of development setup scripts

Both have been merged, refactored, and enhanced for better maintainability.

## License

Internal use for Pentaho/Hitachi Vantara QA work.

## Support

For issues, questions, or improvements, open an issue on GitHub.

---

**Note:** This toolkit is under active development. Scripts are functional but continue to be improved and standardized.
