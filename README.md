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
├── lib/                      # Shared utilities
│   └── common.sh             # Common functions, logging, validation
│
├── dev-environment/          # Development environment setup
│   ├── setup/                # Installation scripts
│   │   ├── main.sh          # Main setup orchestrator
│   │   ├── system/          # System-level installers
│   │   │   ├── install-java.sh       # Java 21 (OpenJDK)
│   │   │   ├── install-docker.sh     # Docker & Docker Compose
│   │   │   ├── install-dev-tools.sh  # Build essentials, git, curl
│   │   │   └── ...          # VSCode, GitHub CLI, environment config
│   │   ├── docker/          # Docker & PostgreSQL setup
│   │   └── pentaho/         # Pentaho dependencies (libwebkit)
│   ├── manage/              # Management utilities
│   │   ├── postgres.sh      # PostgreSQL operations
│   │   └── portainer.sh     # Portainer management
│   ├── docs/                # Documentation
│   ├── resources/           # Package files and configs
│   └── utils/               # Utility scripts
│
├── pentaho/                 # Pentaho platform (under development)
│   ├── server/              # Pentaho Server installation
│   └── pdi/                 # PDI Client installation
│
├── data-platform/           # Big data components (under development)
│   ├── hadoop/              # Hadoop HDFS & YARN
│   └── spark/               # Apache Spark
│
├── ael/                     # AEL Spark execution (being rebuilt)
│   ├── [Old scripts]        # Original ael-automation files
│   └── README.md            # New modular design documentation
│
├── workflows/               # End-to-end orchestrators (coming soon)
│   └── README.md            # Workflow documentation
│
└── docs/                    # General documentation
```

## What's Inside

### Development Environment (`dev-environment/`)

Tools for setting up a complete Pentaho development environment:

- **Java 21** - OpenJDK automatically installed and configured
- **Docker & Docker Compose** - Container runtime
- **PostgreSQL** - With Pentaho databases pre-configured
  - Repository, Quartz, JCR, Logging, Data Mart schemas
  - pgAdmin for database management
- **System Tools** - VSCode, GitHub CLI, dev utilities
- **Pentaho Dependencies** - Libraries and packages required for PDI

**Shared Library:** All scripts source `lib/common.sh` for consistent logging, error handling, and validation.

📖 **[Full Dev Environment Documentation](dev-environment/DEV_README.md)**

---

### Pentaho Platform (`pentaho/`)

PDI installation and cleanup tools:

- **PDI Installer** - Install from local zips with version-based directories
- **Cleanup Script** - Remove all PDI installations, caches, and temp files
- **Parallel Installations** - Multiple PDI versions can coexist
- **Pentaho Server** - Coming soon

📖 **[Pentaho Module Documentation](pentaho/README.md)**

---

### Data Platform (`data-platform/`) - Under Development

Big data infrastructure components:

- **Hadoop 3.4.1+** - HDFS and YARN for distributed storage and processing
- **Spark 4.0.0+** - Distributed computation engine
- **Independent Modules** - Can be used standalone or with AEL

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
# Installs Docker, PostgreSQL, VSCode, and development tools
```

### 2. Installing Pentaho Platform (Coming Soon)
```bash
cd workflows
./setup-basic-pentaho.sh
# PostgreSQL + Pentaho Server + PDI Client + Configurations
```

### 3. Complete AEL Environment (Coming Soon)
```bash
cd workflows
./setup-ael-environment.sh --mode local
# Everything needed for AEL testing
```

### 4. Database Management
```bash
cd dev-environment/manage
./postgres.sh start
# Access pgAdmin at http://localhost:5050
```

### 5. Modular Component Installation (Coming Soon)
```bash
# Install just what you need
cd data-platform/hadoop && ./install.sh
cd data-platform/spark && ./install.sh
cd ael && ./install.sh
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

### Phase 1: Dev Environment (In Progress) ✅
- [x] Consolidate repositories into unified structure
- [x] Migrate all scripts to shared logging library
- [x] Remove redundant code and improve error handling
- [x] Create modular directory structure

### Phase 2: Basic Pentaho (Next)
- [ ] Pentaho Server installation scripts
- [ ] PDI Client installation and configuration
- [ ] PostgreSQL integration and repository setup
- [ ] Basic workflow orchestrator

### Phase 3: Data Platform
- [ ] Extract Hadoop setup from old AEL scripts
- [ ] Extract Spark setup from old AEL scripts
- [ ] Create independent, reusable modules
- [ ] Add comprehensive validation and verification

### Phase 4: AEL Rebuild
- [ ] Rebuild AEL addon installer with modern practices
- [ ] Configuration management improvements
- [ ] Local and YARN mode support
- [ ] Integration with modular components

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
