# Data Platform Components

Hadoop and Spark installation for big data processing and AEL support.

## Overview

This module provides the data platform layer required for:
- AEL (Adaptive Execution Layer) - Pentaho Spark execution
- Big data transformations
- Distributed processing

## Directory Structure

```
data-platform/
├── hadoop/
│   ├── install.sh      # Download and install Hadoop
│   ├── configure.sh    # Setup HDFS, YARN
│   ├── start.sh        # Start Hadoop services
│   ├── stop.sh         # Stop Hadoop services
│   └── verify.sh       # Test HDFS connectivity
└── spark/
    ├── install.sh      # Download and install Spark
    ├── configure.sh    # Setup Spark, History Server
    ├── start.sh        # Start Spark services
    ├── stop.sh         # Stop Spark services
    └── verify.sh       # Test Spark submission
```

## Components

### Hadoop
- **Version:** 3.4.1 (configurable)
- **Mode:** Pseudo-distributed (single node)
- **Services:** HDFS, YARN, NameNode, DataNode
- **Install Location:** `/usr/local/hadoop`

### Spark
- **Version:** 4.0.0 (configurable)
- **Mode:** Standalone or YARN
- **Services:** History Server, Event Logging
- **Install Location:** `/usr/local/spark`

## Prerequisites

- Java 21 (OpenJDK)
- SSH configured for localhost
- Minimum 8GB RAM
- ~10GB disk space

## Quick Start

### Install Hadoop

```bash
cd data-platform/hadoop
./install.sh --version 3.4.1
./configure.sh
./start.sh
./verify.sh
```

### Install Spark

```bash
cd data-platform/spark
./install.sh --version 4.0.0
./configure.sh --master local  # or --master yarn
./start.sh
./verify.sh
```

## Configuration Options

### Hadoop Modes
- **Standalone** - Single JVM, no distributed features
- **Pseudo-distributed** - Full HDFS/YARN on single node (default)
- **Distributed** - Multi-node cluster (future)

### Spark Execution Modes
- **Local** - Single machine, no cluster
- **Standalone** - Spark's own cluster manager
- **YARN** - Hadoop YARN cluster manager (for AEL)

## Verification

After installation, verify services are running:

```bash
# Check Java processes
jps
# Should show: NameNode, DataNode, ResourceManager, NodeManager, HistoryServer

# Check HDFS
hdfs dfs -ls /

# Check Spark
spark-submit --version
```

## Integration with AEL

These components are required for AEL setup. Install before proceeding to `ael/` module.

## Related Modules

- `ael/` - Requires Hadoop + Spark
- `pentaho/pdi/` - Can use Hadoop for transformations
- `workflows/setup-ael-environment.sh` - Installs all dependencies

---

**Status:** Under development - Being extracted from original ael-automation scripts
