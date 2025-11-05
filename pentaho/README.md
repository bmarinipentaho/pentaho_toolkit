# Pentaho Installation & Configuration

Scripts for installing and configuring Pentaho Server and PDI (Pentaho Data Integration) client.

## Overview

This module handles the core Pentaho platform setup:
- **Pentaho Server** - Business analytics platform
- **PDI Client** - Data integration tool (Spoon/Kitchen/Pan)

## Directory Structure

```
pentaho/
├── server/          # Pentaho Server installation
│   ├── install.sh   # Download and install Pentaho Server
│   ├── configure.sh # Connect to PostgreSQL, configure settings
│   ├── start.sh     # Start server
│   └── stop.sh      # Stop server
└── pdi/             # PDI Client installation
    ├── install.sh   # Download and install PDI
    ├── configure.sh # Setup repositories, connections
    └── verify.sh    # Test PDI functionality
```

## Prerequisites

- PostgreSQL running (see `dev-environment/setup/docker/postgres/`)
- Java 17 or 21 installed
- Minimum 4GB RAM available
- ~5GB disk space

## Quick Start

### Install Pentaho Server

```bash
cd pentaho/server
./install.sh
./configure.sh
./start.sh
```

Access at: http://localhost:8080

### Install PDI Client

```bash
cd pentaho/pdi
./install.sh
./configure.sh
```

## Configuration

### Server Database Connection

The server will be configured to use the PostgreSQL databases created in dev-environment:
- Repository: `pentaho_repository`
- Quartz: `pentaho_quartz`
- JCR: `pentaho_jcr`

### PDI Repository

PDI will be configured to connect to the Pentaho Repository for:
- Transformation storage
- Job storage
- Shared database connections

## Usage

Coming soon - scripts under development

## Related Modules

- `dev-environment/` - System setup and PostgreSQL
- `data-platform/` - Hadoop and Spark for AEL
- `ael/` - Spark execution addon

---

**Status:** Under development
