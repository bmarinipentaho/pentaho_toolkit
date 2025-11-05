# Resources Directory

This directory contains supporting resources for the scripts-warehouse project.

## Structure

```
resources/
├── configs/          # Configuration file templates
├── templates/        # Script/file templates
├── sql/             # Additional SQL scripts and queries
├── packages/        # Downloaded packages, installers, dependencies
├── docs/            # Additional documentation and guides
└── README.md        # This file
```

## Best Practices

### `configs/`
Store configuration file templates here:
- Environment-specific configs (dev, test, prod)
- Application configuration templates
- Docker/Kubernetes configs
- Service configuration files

**Example**: 
- `hadoop-site-template.xml`
- `pentaho-server.properties`
- `application.yml`

### `templates/`
Store reusable templates:
- Bash script templates
- Docker compose templates
- CI/CD pipeline templates
- Documentation templates

**Example**:
- `docker-compose.template.yml`
- `systemd-service.template`

### `sql/`
Store SQL-related resources:
- Migration scripts
- Data seeding scripts
- Query collections
- Schema definitions

**Example**:
- `migration-001-add-users.sql`
- `seed-test-data.sql`

### `packages/`
Store downloaded packages and installers:
- Java installers
- Third-party libraries
- Binary distributions
- Archives that are too large for git

**Note**: Add `.gitignore` rules to exclude large binaries

**Example**:
- `openjdk-17.tar.gz`
- `pentaho-di-9.5.tar.gz`

### `docs/`
Store additional documentation:
- Architecture diagrams
- Setup guides
- Troubleshooting guides
- Reference materials

**Example**:
- `architecture.md`
- `troubleshooting.md`
- `api-reference.md`

## Usage in Scripts

To reference resources from scripts:

```bash
# Get script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reference resources
RESOURCES_DIR="$SCRIPT_DIR/../resources"
CONFIG_FILE="$RESOURCES_DIR/configs/my-config.conf"
```

## .gitignore Considerations

Large files in `packages/` should be excluded from git:

```gitignore
# Ignore large packages
resources/packages/*.tar.gz
resources/packages/*.zip
resources/packages/*.jar

# Keep directory structure
!resources/packages/.gitkeep
```
