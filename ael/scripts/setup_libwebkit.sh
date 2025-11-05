#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

echo "Installing libwebkit packages for PDI compatibility..."

# Get the script directory to find libwebkit_files
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LIBWEBKIT_DIR="$PROJECT_ROOT/libwebkit_files"

# Check if libwebkit_files directory exists
if [ ! -d "$LIBWEBKIT_DIR" ]; then
    echo "Error: libwebkit_files directory not found at $LIBWEBKIT_DIR"
    exit 1
fi

# Change to libwebkit_files directory
cd "$LIBWEBKIT_DIR"

# Make files executable
chmod 755 *.deb

echo "Installing libwebkit packages in required order..."

# Install packages in the specified order
# NOTE: User may get dialog boxes to restart servers - select OK
# Permission denied errors can be ignored
echo "Installing libenchant1c2a..."
sudo apt install -y ./libenchant1c2a_1.6.0-11.3build1_amd64.deb

echo "Installing libicu60..."
sudo apt install -y ./libicu60_60.2-3ubuntu3.2_amd64.deb

echo "Installing libjavascriptcoregtk-1.0-0..."
sudo apt install -y ./libjavascriptcoregtk-1.0-0_2.4.11-3ubuntu3_amd64.deb

echo "Installing libwebp6..."
sudo apt install -y ./libwebp6_0.6.1-2ubuntu0.20.04.1_amd64.deb

echo "Installing libwebkitgtk-1.0-0..."
sudo apt install -y ./libwebkitgtk-1.0-0_2.4.11-3ubuntu3_amd64.deb

echo "Installing additional required package..."
sudo apt-get install -y libcanberra-gtk-module

echo "Updating package lists..."
sudo apt update

echo "Libwebkit installation complete!"
echo ""
echo "NOTE: If you plan to use PDI client with DET (Data Extraction Tool),"
echo "you will need to update spoon.sh to set GTK_SWT=1 instead of 0."
echo "This can be done after extracting a full PDI client distribution."
