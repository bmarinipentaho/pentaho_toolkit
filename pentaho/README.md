# Pentaho Module# Pentaho Installation & Configuration



Installation and management tools for Pentaho components.Scripts for installing and configuring Pentaho Server and PDI (Pentaho Data Integration) client.



## Overview## Overview



This module provides automated installation and cleanup for:This module handles the core Pentaho platform setup:

- **PDI (Pentaho Data Integration)** - ETL client (Spoon, Kitchen, Pan)- **Pentaho Server** - Business analytics platform

- **Pentaho Server** - Business analytics platform (coming soon)- **PDI Client** - Data integration tool (Spoon/Kitchen/Pan)



## PDI Installation## Directory Structure



### Quick Start```

pentaho/

```bash├── server/          # Pentaho Server installation

# Install from local zip│   ├── install.sh   # Download and install Pentaho Server

./pentaho/pdi/install-pdi.sh --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip│   ├── configure.sh # Connect to PostgreSQL, configure settings

│   ├── start.sh     # Start server

# Verify installation│   └── stop.sh      # Stop server

ls -l ~/pentaho/pdi/current└── pdi/             # PDI Client installation

~/pentaho/pdi/current/spoon.sh    ├── install.sh   # Download and install PDI

```    ├── configure.sh # Setup repositories, connections

    └── verify.sh    # Test PDI functionality

### Installation Modes```



#### 1. Local Zip File (Recommended)## Prerequisites



Download the PDI zip from the build site, then install:- PostgreSQL running (see `dev-environment/setup/docker/postgres/`)

- Java 17 or 21 installed

```bash- Minimum 4GB RAM available

./pentaho/pdi/install-pdi.sh --zip-file /path/to/pdi-ee-client-11.0.0.0-203.zip- ~5GB disk space

```

## Quick Start

**Features:**

- Automatic version and build detection from filename### Install Pentaho Server

- Creates version-specific directory (`11.0.0.0-203`)

- Creates `current` symlink for easy access```bash

- Makes all shell scripts executablecd pentaho/server

./install.sh

#### 2. Direct Download (Experimental)./configure.sh

./start.sh

```bash```

./pentaho/pdi/install-pdi.sh --version 11.0-QAT --build 203

```Access at: http://localhost:8080



**Note:** The build site uses JavaScript and Artifactory redirects. Direct downloads may not work reliably. Recommended to download manually first.### Install PDI Client



### Installation Options```bash

cd pentaho/pdi

```bash./install.sh

Options:./configure.sh

  --zip-file PATH       Install from local zip file```

  --version VERSION     PDI version (e.g., 11.0-QAT, 10.2.0.0)

  --build NUMBER        Build number## Configuration

  --edition EDITION     ce or ee (default: ee)

  --install-dir DIR     Custom installation directory### Server Database Connection

  --no-symlink         Don't create 'current' symlink

  --force              Overwrite existing installationThe server will be configured to use the PostgreSQL databases created in dev-environment:

  -h, --help           Show help- Repository: `pentaho_repository`

```- Quartz: `pentaho_quartz`

- JCR: `pentaho_jcr`

### Examples

### PDI Repository

```bash

# Install EE edition (default)PDI will be configured to connect to the Pentaho Repository for:

./pentaho/pdi/install-pdi.sh --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip- Transformation storage

- Job storage

# Install CE edition- Shared database connections

./pentaho/pdi/install-pdi.sh --zip-file ~/Downloads/pdi-ce-client-11.0.0.0-203.zip

## Usage

# Custom installation directory

./pentaho/pdi/install-pdi.sh \Coming soon - scripts under development

  --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip \

  --install-dir /opt/pdi/11.0.0.0-203## Related Modules



# Force overwrite existing installation- `dev-environment/` - System setup and PostgreSQL

./pentaho/pdi/install-pdi.sh \- `data-platform/` - Hadoop and Spark for AEL

  --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip \- `ael/` - Spark execution addon

  --force

```---



### Installation Paths**Status:** Under development


- **Base directory:** `~/pentaho/pdi/`
- **Version-specific:** `~/pentaho/pdi/{version}-{build}/`
- **Current symlink:** `~/pentaho/pdi/current` → `{version}-{build}/`

### Parallel Installations

Multiple PDI versions can be installed side-by-side:

```bash
~/pentaho/pdi/
├── 10.2.0.0-950/
├── 11.0.0.0-203/
├── 11.0.0.0-210/
└── current -> 11.0.0.0-210/
```

Switch between versions by updating the symlink or using full paths.

## Using PDI

### Environment Setup

```bash
# Add to ~/.bashrc
export PDI_HOME=~/pentaho/pdi/current
export PATH=$PATH:$PDI_HOME
```

### Running PDI Tools

```bash
# Spoon (GUI)
cd ~/pentaho/pdi/current
./spoon.sh

# Kitchen (Job runner)
./kitchen.sh -file=/path/to/job.kjb -level=Basic

# Pan (Transformation runner)
./pan.sh -file=/path/to/transformation.ktr -level=Basic

# Carte (Server)
./carte.sh 8080
```

## Cleanup

The cleanup script removes all Pentaho installations, caches, and temporary files.

### Preview Cleanup

```bash
# Dry-run to see what would be deleted
./pentaho/cleanup.sh --dry-run
```

### Complete Cleanup

```bash
# Remove everything
./pentaho/cleanup.sh --all
```

### Selective Cleanup

```bash
# PDI installations only
./pentaho/cleanup.sh --pdi-only

# Caches and temp files only
./pentaho/cleanup.sh --caches-only

# Keep log files
./pentaho/cleanup.sh --keep-logs
```

### Cleanup Options

```bash
Options:
  --dry-run            Show what would be deleted
  --pdi-only          Remove only PDI installations
  --caches-only       Remove only caches/temp files
  --all               Remove everything (default)
  --keep-logs         Don't delete log files
  --auto-confirm      Skip confirmation prompts
  -h, --help          Show help
```

### Cleanup Targets

The cleanup script removes:

**PDI Installations:**
- `~/pentaho/pdi/`

**Configuration & Hidden Folders:**
- `~/.pentaho/`
- `~/.kettle/`

**Caches & Temp Files:**
- `~/.pentaho/cache/`
- `~/.pentaho/metastore/`
- `/tmp/pentaho/`, `/tmp/kettle/`
- `/tmp/vfs_cache*`
- `/tmp/kettle_*`, `/tmp/pdi_*`

**Logs (optional):**
- `~/.pentaho/logs/`
- `~/.kettle/logs/`
- `~/.pentaho/*.log`
- `~/.kettle/*.log`

## Build Site Access

PDI builds are available at: https://build.orl.eng.hitachivantara.com/hosted/

**Available versions:**
- `11.0-QAT` - Latest QA testing builds (default)
- `10.2.0.x` - 10.2 release versions
- `10.3.0.x` - 10.3 release versions

**File naming pattern:**
- `pdi-ee-client-{version}-{build}.zip` (Enterprise Edition)
- `pdi-ce-client-{version}-{build}.zip` (Community Edition)

**Note:** Files are hosted on Artifactory and may require authentication or VPN access.

## Troubleshooting

### Installation Issues

**Problem:** Zip extraction fails
```bash
# Check if unzip is installed
sudo apt install unzip

# Verify zip file is not corrupted
unzip -t /path/to/pdi.zip
```

**Problem:** Scripts not executable
```bash
# Make scripts executable
chmod +x ~/pentaho/pdi/current/*.sh
```

### Runtime Issues

**Problem:** Java not found
```bash
# Install Java (required for PDI)
cd ~/projects/pentaho_toolkit
./dev-environment/setup/system/install-java.sh

# Verify Java installation
java -version
echo $JAVA_HOME
```

**Problem:** Out of memory errors
```bash
# Edit spoon.sh and increase memory
# Find PENTAHO_DI_JAVA_OPTIONS and adjust -Xmx
export PENTAHO_DI_JAVA_OPTIONS="-Xms2048m -Xmx4096m"
```

## Integration with Dev Environment

PDI requires Java and other dependencies installed via dev-environment:

```bash
# Install complete dev environment
cd ~/projects/pentaho_toolkit/dev-environment
./setup/main.sh

# Or install just Java
./setup/system/install-java.sh
```

## Future Enhancements

- [ ] Pentaho Server installation
- [ ] Automated configuration management
- [ ] Database connection templates
- [ ] Plugin management
- [ ] Environment-specific configs (dev/qa/prod)
