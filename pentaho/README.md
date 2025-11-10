# Pentaho Module

Installation and cleanup tools for Pentaho components.

## Table of Contents

- [PDI Installation](#pdi-installation)
- [Server Installation](#server-installation)
- [Cleanup](#cleanup)
- [Build Site](#build-site)

## PDI Installation

### Quick Start

```bash
# Install from local zip with license
./pentaho/pdi/install-pdi.sh \
  --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip \
  --license-url https://flex1826-uat.compliance.flexnetoperations.com/instances/YA6CTUK7XNAJ/request

# Run PDI
cd ~/pentaho/current/pdi/data-integration
./spoon.sh
```

### Installation Structure

```
~/pentaho/
├── 11.0-QAT/203/
│   └── pdi/
│       ├── data-integration/    # Main PDI installation
│       ├── license-installer/   # License tools
│       └── jdbc-distribution/   # JDBC distribution tools
├── project_profiles/            # Project profiles (kettle props, metastore)
└── current -> 11.0-QAT/203      # Symlink to current version
```

### Options

```bash
./pentaho/pdi/install-pdi.sh --help
```

**Key options:**
- `--zip-file PATH` - Install from local zip (recommended)
- `--license-url URL` - Install license automatically
- `--version VERSION` - Specify version (e.g., 11.0-QAT)
- `--build NUMBER` - Specify build number
- `--edition ce|ee` - Edition (default: ee)
- `--force` - Overwrite existing installation

### Examples

```bash
# Install EE edition with license (recommended)
./pentaho/pdi/install-pdi.sh \
  --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip \
  --license-url https://flex1826-uat.compliance.flexnetoperations.com/instances/YA6CTUK7XNAJ/request

# Install CE edition  
./pentaho/pdi/install-pdi.sh \
  --zip-file ~/Downloads/pdi-ce-client-11.0.0.0-203.zip \
  --edition ce

# Force overwrite existing installation
./pentaho/pdi/install-pdi.sh \
  --zip-file ~/Downloads/pdi-ee-client-11.0.0.0-203.zip \
  --force
```

## Server Installation

### Quick Start

```bash
# Auto-discover server + plugins in Downloads folder
./pentaho/server/install-server.sh

# Specific directory with server + plugins
./pentaho/server/install-server.sh ~/pentaho-builds/11.0.0.0-204/

# With license automation
./pentaho/server/install-server.sh --license-url https://flexnet.example.com/license
```

### Installation Structure

```
~/pentaho/
├── 11.0.0.0/204/
│   └── server/
│       ├── pentaho-server/          # Main server installation
│       │   ├── pentaho-solutions/
│       │   │   └── system/          # Standard plugins (paz, pdd)
│       │   ├── data/                # Operations mart (PIR)
│       │   ├── tomcat/              # Tomcat application server
│       │   └── start-pentaho.sh     # Startup script
│       ├── license-installer/       # License tools
│       ├── jdbc-distribution/       # JDBC drivers
│       └── server-current -> pentaho-server/  # Symlink
```

### Plugin Discovery

The installer automatically discovers and installs plugins:

**Supported Plugins:**
- `paz-plugin` - Pentaho Analyzer → `pentaho-solutions/system/`
- `pdd-plugin` - Pentaho Data Access → `pentaho-solutions/system/`
- `pir-plugin` - Pentaho Interactive Reporting → `data/`
- `operations-mart` - Operations Mart → `data/`

**Discovery Patterns:**
```
# Pattern 1: Flat directory
~/Downloads/
├── pentaho-server-ee-11.0.0.0-204.zip
├── paz-plugin-ee-11.0.0.0-204.zip
└── pir-plugin-ee-11.0.0.0-204.zip

# Pattern 2: Nested plugins
~/Downloads/server/
├── pentaho-server-ee-11.0.0.0-204.zip
└── plugins/
    ├── paz-plugin-ee-11.0.0.0-204.zip
    └── pir-plugin-ee-11.0.0.0-204.zip
```

**Version Validation:**
- Plugin versions must match server version
- Mismatched plugins are skipped with warnings
- Non-plugin zips (like PDI) are automatically ignored

### Server Management

```bash
# Start server
./pentaho/server/manage-server.sh start

# Stop server
./pentaho/server/manage-server.sh stop

# Check status
./pentaho/server/manage-server.sh status

# View logs
./pentaho/server/manage-server.sh logs

# Connect to Karaf console
./pentaho/server/manage-server.sh karaf

# Clean work directories
./pentaho/server/manage-server.sh clean
```

### PostgreSQL Configuration

```bash
# Configure server to use PostgreSQL
./pentaho/server/configure-server.sh ~/pentaho/11.0.0.0/204/server-current \
  --host localhost \
  --port 5432 \
  --user pentaho \
  --password password
```

**Configured Databases:**
- `hibernate` - JCR repository
- `quartz` - Scheduler
- `jackrabbit` - Content repository

### Access

After starting the server:
- **Console:** http://localhost:8080/pentaho
- **Default Credentials:** admin/password
- **Karaf Console:** ssh://localhost:8181 (karaf/karaf)

### Examples

```bash
# Install with all 4 plugins
./pentaho/server/install-server.sh

# Force reinstall
./pentaho/server/install-server.sh --force

# Install with license
./pentaho/server/install-server.sh \
  --license-url https://flexnet.example.com/instances/XXXXX/request

# Start server
./pentaho/server/manage-server.sh start

# View logs in real-time
./pentaho/server/manage-server.sh logs
```

## Cleanup

Remove all PDI installations, caches, and temp files.

```bash
# Preview what will be deleted
./pentaho/cleanup.sh --dry-run

# Remove everything
./pentaho/cleanup.sh --auto-confirm

# Remove only PDI installations
./pentaho/cleanup.sh --pdi-only --auto-confirm

# Remove only Server installations
./pentaho/cleanup.sh --server-only --auto-confirm
```

**Cleanup targets:**
- PDI installations: `~/pentaho/pdi/`
- Server installations: `~/pentaho/*/*/server/`
- Hidden folders: `~/.pentaho`, `~/.kettle`
- Caches: `~/.pentaho/cache`, `~/.pentaho/metastore`
- Temp files: `/tmp/pentaho`, `/tmp/kettle`, `/tmp/vfs_cache*`

## Build Site

**Build Location:** https://build.orl.eng.hitachivantara.com/hosted/

### PDI Builds
- Default version: `11.0-QAT`
- File pattern: `pdi-{edition}-client-{version}-{build}.zip`
- Editions: `ee` (Enterprise) or `ce` (Community)

### Server Builds
- File pattern: `pentaho-server-{edition}-{version}-{build}.zip`
- Plugin pattern: `{plugin-name}-{edition}-{version}-{build}.zip`
- Plugins: paz-plugin, pdd-plugin, pir-plugin, pentaho-operations-mart

**Note:** Build site uses JavaScript/Artifactory. Manual download recommended.

## Requirements

- Java 21+ (run `./dev-environment/setup/system/install-java.sh`)
- `unzip` command

## Troubleshooting

**Scripts not executable:**
```bash
chmod +x ~/pentaho/current/pdi/data-integration/*.sh
```

**Java not found:**
```bash
./dev-environment/setup/system/install-java.sh
```

**Out of memory:**
```bash
export PENTAHO_DI_JAVA_OPTIONS="-Xms2048m -Xmx4096m"
```
