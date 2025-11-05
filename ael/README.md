# AEL (Adaptive Execution Layer)

Pentaho Spark execution addon for distributed PDI transformation processing.

## Overview

AEL enables PDI transformations to execute on Spark, providing:
- Distributed processing across cluster nodes
- Scalability for large datasets
- Integration with Hadoop ecosystem

## What is AEL?

AEL is Pentaho's execution layer that translates PDI transformations into Spark jobs, allowing them to run on distributed Spark clusters instead of locally.

## Directory Structure

```
ael/
├── install.sh       # Install Spark execution addon
├── configure.sh     # Setup daemon, application.properties
├── start.sh         # Start AEL daemon
├── stop.sh          # Stop AEL daemon
├── verify.sh        # Test AEL execution
└── configs/         # Configuration templates
    ├── local.properties       # Local mode config
    └── yarn.properties        # YARN mode config
```

## Prerequisites

**Required:**
- Pentaho PDI client installed (`pentaho/pdi/`)
- Hadoop 3.4.1+ (`data-platform/hadoop/`)
- Spark 4.0.0+ (`data-platform/spark/`)
- Java 21

**Optional:**
- PostgreSQL for metadata storage
- HBase for distributed caching

## Installation

```bash
# 1. Ensure prerequisites are met
cd data-platform/hadoop && ./verify.sh
cd data-platform/spark && ./verify.sh

# 2. Install AEL addon
cd ael
./install.sh /path/to/pdi-ee-client-spark-execution-addon.zip

# 3. Configure for local or YARN mode
./configure.sh --mode local   # For local testing
# OR
./configure.sh --mode yarn    # For YARN cluster

# 4. Start the daemon
./start.sh

# 5. Verify it works
./verify.sh
```

## Configuration Modes

### Local Mode
- Spark runs on local machine
- `sparkMaster=local[*]`
- Good for: Testing, development, small datasets

### YARN Mode
- Spark runs on Hadoop YARN cluster
- `sparkMaster=yarn`
- `sparkDeployMode=client`
- Good for: Production, large datasets, distributed processing

## AEL Daemon

The daemon manages Spark job submissions:
- Listens for transformation execution requests
- Translates PDI steps to Spark operations
- Manages executor lifecycle
- Provides websocket interface

**Default Port:** 53005 (configurable)

## Artifacts

AEL requires two main artifacts:
1. **PDI EE Client** - Base PDI with Spark support
2. **Spark Execution Addon** - AEL daemon and libraries

These can be obtained from:
- JFrog Artifactory (with API key)
- Local build artifacts
- Pre-downloaded zip files

## Usage

### Start Daemon
```bash
./start.sh
# Access logs: tail -f ~/ael_deployment/AEL/data-integration/spark-execution-daemon/logs/daemon.log
```

### Stop Daemon
```bash
./stop.sh
```

### Verify Status
```bash
./verify.sh
# Checks:
# - Daemon is running
# - HDFS executor jar present
# - Spark configuration valid
# - Test transformation executes
```

## Troubleshooting

### Daemon Won't Start
- Check Java version: `java -version` (must be 21)
- Check HDFS: `hdfs dfs -ls /`
- Check Spark: `spark-submit --version`
- Review logs in `~/ael_deployment/AEL/data-integration/spark-execution-daemon/logs/`

### Connection Refused Errors
- Verify Hadoop services running: `jps`
- Check firewall: Ports 8020 (HDFS), 8032 (YARN) must be open
- Verify daemon websocket port accessible

### ClassNotFoundError
- Ensure all required jars in classpath
- Check `pentaho-kettle-core` jar present
- Verify spark executor zip uploaded to HDFS

## Configuration Files

### application.properties
Main configuration file for AEL daemon:
- Spark master URL
- HDFS paths
- Hadoop/HBase configuration directories
- Logging levels
- Websocket settings

### Generated Configs
The `configure.sh` script creates:
- `application.properties.local` - Local mode template
- `application.properties.yarn` - YARN mode template
- `application.properties` - Active configuration (symlink or copy)

## Integration Points

- **PDI Transformations** - Execute via Kitchen/Pan with AEL engine
- **HDFS** - Stores executor jars and event logs
- **Spark History Server** - View job execution history
- **Pentaho Server** - Can trigger AEL transformations via schedules

## Migration from Old Scripts

This module replaces the monolithic `ael-automation` approach with:
- ✅ Modular installation (Hadoop/Spark separate)
- ✅ Better configuration management
- ✅ Proper error handling and validation
- ✅ Shared logging framework
- ✅ Independent testing of each layer

## Related Modules

- `pentaho/pdi/` - PDI client required
- `data-platform/hadoop/` - HDFS storage
- `data-platform/spark/` - Execution engine
- `workflows/setup-ael-environment.sh` - Automated full setup

---

**Status:** Under development - Will be rebuilt from scratch with modern practices
