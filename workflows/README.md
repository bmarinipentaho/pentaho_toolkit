# Workflow Orchestrators

End-to-end setup scripts for common scenarios.

## Overview

These workflows combine multiple modules to set up complete environments with a single command.

## Available Workflows

### setup-basic-pentaho.sh
Sets up a basic Pentaho development environment.

**Includes:**
- PostgreSQL database (via Docker)
- Pentaho Server
- PDI Client
- Database connections configured

**Usage:**
```bash
./setup-basic-pentaho.sh
```

**Time:** ~15-20 minutes  
**Disk:** ~5GB

---

### setup-ael-environment.sh
Complete AEL testing environment with all dependencies.

**Includes:**
- Everything from basic-pentaho
- Hadoop 3.4.1
- Spark 4.0.0
- AEL daemon configured

**Usage:**
```bash
./setup-ael-environment.sh --mode local
# OR
./setup-ael-environment.sh --mode yarn
```

**Time:** ~30-40 minutes  
**Disk:** ~15GB

---

### setup-development.sh
Just the development tools, no Pentaho.

**Includes:**
- Docker & Docker Compose
- VS Code
- GitHub CLI
- Development utilities
- PostgreSQL (optional)

**Usage:**
```bash
./setup-development.sh
```

**Time:** ~10 minutes  
**Disk:** ~2GB

---

## Workflow Architecture

Each workflow follows this pattern:

```bash
#!/bin/bash
set -euo pipefail

# Source shared library
source "$(dirname "$0")/../shared/lib/common.sh"

# Validation phase
check_prerequisites
validate_disk_space
confirm_installation

# Installation phase
install_module_1
install_module_2
configure_integrations

# Verification phase
verify_installation
print_summary
```

## Module Dependencies

```
setup-development.sh
    └─> dev-environment/

setup-basic-pentaho.sh
    ├─> dev-environment/
    └─> pentaho/

setup-ael-environment.sh
    ├─> dev-environment/
    ├─> pentaho/
    ├─> data-platform/hadoop/
    ├─> data-platform/spark/
    └─> ael/
```

## Customization

All workflows support:
- `--yes` - Auto-confirm all prompts
- `--skip-<module>` - Skip specific components
- `--versions-file` - Specify version overrides

Example:
```bash
./setup-ael-environment.sh \
    --yes \
    --skip-pentaho-server \
    --versions-file my-versions.conf
```

## Creating Custom Workflows

Template structure:

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$TOOLKIT_ROOT/shared/lib/common.sh"

header "My Custom Workflow"

# Your module calls here
"$TOOLKIT_ROOT/pentaho/pdi/install.sh"
"$TOOLKIT_ROOT/data-platform/spark/install.sh"

success "Custom setup complete!"
```

## Recovery

If a workflow fails midway:
1. Check logs for the failing component
2. Fix the issue
3. Run the workflow again - it's idempotent
4. Or manually run individual module scripts

## Status Files

Workflows create status markers:
```
~/.pentaho-toolkit/
    ├── basic-pentaho.installed
    ├── ael-environment.installed
    └── last-run.log
```

---

**Status:** Under development - Placeholders for future implementation
