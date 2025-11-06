# Data Platform Components

Hadoop and Spark installation for big data processing and AEL support.

## Overview

This module provides the data platform layer required for:
- **AEL (Adaptive Execution Layer)** - Pentaho Spark execution engine
- Big data transformations
- Distributed processing and analytics

## Quick Start

```bash
# Install both Hadoop and Spark with defaults
./data-platform/install.sh

# Install only Hadoop
./data-platform/install.sh --hadoop-only

# Install with specific versions
./data-platform/install.sh --hadoop-version 3.3.6 --spark-version 3.5.4

# Clean up all installations
./data-platform/cleanup.sh
```

## Directory Structure

```
data-platform/
├── install.sh          # Master installer (Hadoop + Spark)
├── cleanup.sh          # Remove all installations
├── README.md
├── hadoop/
│   └── install-hadoop.sh
└── spark/
    └── install-spark.sh
```

## Components

### Hadoop
- **Default Version:** 3.4.1
- **Mode:** Pseudo-distributed (single node)
- **Install Location:** `~/data-platform/installs/hadoop-{version}/`
- **Symlink:** `~/data-platform/installs/hadoop-current`
- **Size:** ~1.7GB

### Spark
- **Default Version:** 4.0.0
- **Hadoop Compatibility:** hadoop3
- **Install Location:** `~/data-platform/installs/spark-{version}/`
- **Symlink:** `~/data-platform/installs/spark-current`
- **Size:** ~577MB

## Prerequisites

- **Java:** OpenJDK 21 (installed via dev-environment setup)
- **Tools:** curl, tar
- **Disk Space:** ~3GB for both components
- **Memory:** Minimum 8GB RAM recommended

## Installation

### Using the Master Installer (Recommended)

```bash
# Install both Hadoop and Spark
./data-platform/install.sh

# Install only Hadoop
./data-platform/install.sh --hadoop-only

# Install only Spark
./data-platform/install.sh --spark-only

# Install specific versions
./data-platform/install.sh --hadoop-version 3.3.6 --spark-version 3.5.4

# Non-interactive mode
./data-platform/install.sh -y
```

### Using Individual Installers

```bash
# Install Hadoop
./data-platform/hadoop/install-hadoop.sh --version 3.4.1

# Install Spark
./data-platform/spark/install-spark.sh --version 4.0.0
```

### Environment Variables

After installation, add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Hadoop
export HADOOP_HOME=$HOME/data-platform/installs/hadoop-current
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Spark
export SPARK_HOME=$HOME/data-platform/installs/spark-current
export PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin
```

## Cleanup

Remove all installations and data:

```bash
# Dry run (see what will be deleted)
./data-platform/cleanup.sh --dry-run

# Remove everything
./data-platform/cleanup.sh

# Remove only Hadoop
./data-platform/cleanup.sh --hadoop-only

# Remove only Spark
./data-platform/cleanup.sh --spark-only
```

## Version Management

The installers support multiple parallel installations:

```bash
# Install Hadoop 3.4.1
./data-platform/hadoop/install-hadoop.sh --version 3.4.1

# Install Hadoop 3.3.6 alongside
./data-platform/hadoop/install-hadoop.sh --version 3.3.6

# The symlink hadoop-current points to the most recently installed version
# You can manually change it:
cd ~/data-platform/installs
rm hadoop-current
ln -s hadoop-3.3.6 hadoop-current
```

## Integration with Dev Environment

The data platform can be installed as part of the main setup:

```bash
# Run main dev environment setup
./dev-environment/setup/main.sh

# When prompted, choose "Y" to install Hadoop and Spark
```

## Integration with AEL

These components are required for AEL (Adaptive Execution Layer) setup:

- **Hadoop 3.4.1** - HDFS and YARN for distributed processing
- **Spark 4.0.0** - Execution engine for AEL transformations

Install the data platform before proceeding to the `ael/` module.

## Advanced Usage

### Command Line Options

#### Master Installer (`install.sh`)
```bash
./data-platform/install.sh [OPTIONS]

Options:
  --hadoop-only          Install only Hadoop (skip Spark)
  --spark-only           Install only Spark (skip Hadoop)
  --hadoop-version VER   Hadoop version (default: 3.4.1)
  --spark-version VER    Spark version (default: 4.0.0)
  -y, --yes              Auto-confirm prompts
  -h, --help             Show help
```

#### Hadoop Installer
```bash
./data-platform/hadoop/install-hadoop.sh [OPTIONS]

Options:
  --version VER          Hadoop version to install
  --install-dir DIR      Installation directory
  --force                Reinstall if already exists
  -h, --help             Show help
```

#### Spark Installer
```bash
./data-platform/spark/install-spark.sh [OPTIONS]

Options:
  --version VER          Spark version to install
  --hadoop-version VER   Hadoop compatibility (default: hadoop3)
  --install-dir DIR      Installation directory
  --force                Reinstall if already exists
  -h, --help             Show help
```

#### Cleanup Script
```bash
./data-platform/cleanup.sh [OPTIONS]

Options:
  --dry-run              Show what would be deleted
  --hadoop-only          Remove only Hadoop
  --spark-only           Remove only Spark
  --keep-logs            Keep log files
  --auto-confirm         Skip confirmation
  -h, --help             Show help
```

## Troubleshooting

### Installation Issues

**Problem:** Download fails with 404 error
- **Solution:** Older Spark versions must use `archive.apache.org` (handled automatically)

**Problem:** Permission denied
- **Solution:** Ensure scripts are executable: `chmod +x data-platform/**/*.sh`

**Problem:** Out of disk space
- **Solution:** Clean up old installations: `./data-platform/cleanup.sh`

### Version Compatibility

- **Spark 3.x**: Uses `spark-{version}-bin-hadoop3.tgz` naming
- **Spark 4.x**: Uses `spark-{version}-bin-hadoop3-connect.tgz` naming
- This is handled automatically by the installer

## Related Modules

- **`ael/`** - Requires Hadoop + Spark
- **`pentaho/pdi/`** - Can use Hadoop for transformations
- **`dev-environment/`** - Base system setup (Java, Docker, PostgreSQL)

---

**Status:** ✅ Core installation complete - Configuration scripts planned for future updates
