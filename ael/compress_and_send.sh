#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

# Define the project directory
PROJECT_DIR=$(dirname "$(realpath "$0")")

# Default values for parameters
DEFAULT_TARBALL_FILE="ael_automation.tgz"
DEFAULT_REMOTE_USER="devuser"
DEFAULT_REMOTE_HOST="your_remote_host"
DEFAULT_REMOTE_DIR="/home/devuser"

# Accept parameter values from the command line
REMOTE_HOST=${1:-$DEFAULT_REMOTE_HOST}
REMOTE_USER=${2:-$DEFAULT_REMOTE_USER}
REMOTE_DIR=${3:-$DEFAULT_REMOTE_DIR}
TARBALL_FILE=${4:-$DEFAULT_TARBALL_FILE}

# Compress the project directory into a tarball
cd $PROJECT_DIR
tar -czvf $TARBALL_FILE *

# Send the tarball to the remote server via SFTP
sftp $REMOTE_USER@$REMOTE_HOST <<EOF
put $TARBALL_FILE $REMOTE_DIR
bye
EOF

# Clean up the tarball
rm $TARBALL_FILE

echo "Files compressed and sent successfully."