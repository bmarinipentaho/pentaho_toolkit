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
├── ael/                        # AEL environment automation
│   ├── deploy_ael.sh          # Main deployment script
│   ├── remove_ael.sh          # Cleanup script
│   ├── scripts/               # Component installers (Hadoop, Spark, AEL)
│   └── siteFiles/             # Configuration templates
│
├── dev-environment/           # Development environment setup
│   ├── setup/                 # Installation scripts
│   │   ├── main.sh           # Main setup orchestrator
│   │   ├── docker/           # Docker & PostgreSQL setup
│   │   ├── pentaho/          # Pentaho dependencies
│   │   └── system/           # System tools (VSCode, Docker, etc.)
│   ├── manage/               # Management utilities
│   │   ├── postgres.sh       # PostgreSQL operations
│   │   └── portainer.sh      # Portainer management
│   └── lib/                  # Legacy library location
│
├── shared/                    # Shared utilities (future use)
│   └── lib/
│       └── common.sh         # Common functions, logging, validation
│
└── docs/                      # Documentation

```

## What's Inside

### AEL Environment (`ael/`)

Automated setup for testing Pentaho transformations with Spark execution:

- **Java 21** - OpenJDK installation and configuration
- **Hadoop 3.4.1** - HDFS setup with single-node configuration
- **Spark 3.5.4** - With history server and event logging
- **AEL Daemon** - Pentaho Spark execution harness
- **Flexible deployment** - Support for local files, URLs, or JFrog API keys

**Key Features:**
- Version overrides via flags (`--hadoop-version`, `--spark-version`)
- YARN mode support (`--yarn-mode`)
- Comprehensive cleanup with selective purging
- Configuration regeneration without redeployment

📖 **[Full AEL Documentation](ael/AEL_README.md)**

### Development Environment (`dev-environment/`)

Tools for setting up a complete Pentaho development environment:

- **Docker & Docker Compose** - Container runtime
- **PostgreSQL** - With Pentaho databases pre-configured
  - Repository, Quartz, JCR, Logging, Data Mart schemas
  - pgAdmin for database management
- **System Tools** - VSCode, GitHub CLI, dev utilities
- **Pentaho Dependencies** - Libraries and packages required for PDI

📖 **[Full Dev Environment Documentation](dev-environment/DEV_README.md)**

### Shared Libraries (`shared/`)

Common utilities used across the toolkit (under development):

- **Logging framework** - Colored output, log levels, consistent formatting
- **Validation functions** - Input validation, prerequisite checks
- **Service management** - Health checks, port monitoring
- **Error handling** - Standardized error reporting

## Use Cases

### 1. QA Testing AEL Transformations
```bash
cd ael
./deploy_ael.sh /path/to/pdi-ee-client.zip
# Run your transformations
./remove_ael.sh --purge-hdfs
```

### 2. Setting Up a New Development VM
```bash
cd dev-environment
./setup/main.sh
# Installs Docker, PostgreSQL, VSCode, and development tools
```

### 3. Testing YARN Mode
```bash
cd ael
./deploy_ael.sh --yarn-mode /path/to/artifacts.zip
```

### 4. Database Development
```bash
cd dev-environment
./manage/postgres.sh start
# Access pgAdmin at http://localhost:5050
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

- [ ] Migrate all scripts to use shared logging library
- [ ] Parameterize hardcoded values (users, paths, ports)
- [ ] Add comprehensive validation and health checks
- [ ] Create automated smoke tests
- [ ] Docker containerization for AEL
- [ ] CI/CD pipeline with shellcheck

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
