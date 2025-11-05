# Pentaho Module

Installation and cleanup tools for Pentaho components.

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

## Cleanup

Remove all PDI installations, caches, and temp files.

```bash
# Preview what will be deleted
./pentaho/cleanup.sh --dry-run

# Remove everything
./pentaho/cleanup.sh --auto-confirm

# Remove only PDI installations
./pentaho/cleanup.sh --pdi-only --auto-confirm
```

## Build Site

PDI builds: https://build.orl.eng.hitachivantara.com/hosted/

- Default version: `11.0-QAT`
- File pattern: `pdi-{edition}-client-{version}-{build}.zip`
- Editions: `ee` (Enterprise) or `ce` (Community)

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
