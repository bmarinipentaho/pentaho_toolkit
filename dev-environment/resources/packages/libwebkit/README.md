# LibWebKitGTK 1.0 for Pentaho

## Overview
These legacy `.deb` packages provide the older WebKitGTK 1.0 library required by Pentaho's SWT-based UI components (Spoon, Report Designer, etc.).

## Required Packages (Install in Order)

1. `libenchant1c2a_1.6.0-11.3build1_amd64.deb` - Spell checking library
2. `libicu60_60.2-3ubuntu3.2_amd64.deb` - International Components for Unicode
3. `libjavascriptcoregtk-1.0-0_2.4.11-3ubuntu3_amd64.deb` - JavaScript engine
4. `libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb` - WebP image format support
5. `libwebkitgtk-1.0-0_2.4.11-3ubuntu3_amd64.deb` - WebKitGTK 1.0 library

## Installation

### Automated (Recommended)
```bash
cd /path/to/scripts-warehouse
./scripts/install-pentaho-dependencies.sh
```

### Manual Installation
```bash
cd resources/packages/libwebkit

# Install packages in order
sudo apt install ./libenchant1c2a_1.6.0-11.3build1_amd64.deb
sudo apt install ./libicu60_60.2-3ubuntu3.2_amd64.deb
sudo apt install ./libjavascriptcoregtk-1.0-0_2.4.11-3ubuntu3_amd64.deb
sudo apt install ./libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb
sudo apt install ./libwebkitgtk-1.0-0_2.4.11-3ubuntu3_amd64.deb

# Install additional GTK module
sudo apt-get install -y libcanberra-gtk-module

# Update package cache
sudo apt update
```

## Notes

- **Ubuntu 22.04**: These packages are from Ubuntu 20.04 (Focal) but work on 22.04
- **Restart Services Dialog**: If prompted to restart services during installation, select OK
- **Permission Denied**: Can be safely ignored if it occurs
- **Required for**: Pentaho Spoon, Report Designer, Schema Workbench (any SWT-based UI)
- **Not required for**: Headless PDI operations, server deployments

## Source
Original packages from Ubuntu 20.04 (Focal) repositories, compatible with Ubuntu 22.04 (Jammy).

## Verification
After installation, verify with:
```bash
dpkg -l | grep -E 'libwebkit|libjavascriptcore'
```

You should see `libwebkitgtk-1.0-0` and `libjavascriptcoregtk-1.0-0` installed.
