#!/bin/bash

# Enable debugging and stop execution on errors
set -x
set -e

JAVA_VERSION=21

# Detect if requested OpenJDK major is installed
JAVA_INSTALLED=0
if java -version 2>&1 | grep -q "openjdk version \"21"; then
    JAVA_INSTALLED=1
fi

if [ $JAVA_INSTALLED -ne 1 ]; then
    echo "OpenJDK $JAVA_VERSION not detected. Installing..."
    sudo apt-get update -y || true
    sudo apt-get install -y "openjdk-$JAVA_VERSION-jdk"
else
    echo "OpenJDK $JAVA_VERSION already present."
fi

# Resolve JAVA_HOME using update-alternatives path
JAVA_BIN_PATH=$(readlink -f /usr/bin/java || true)
JAVA_HOME_DIR="${JAVA_BIN_PATH%/bin/java}"

if [ -z "$JAVA_HOME_DIR" ] || [ ! -d "$JAVA_HOME_DIR" ]; then
    echo "Unable to determine JAVA_HOME; aborting." >&2
    exit 1
fi

# Persist JAVA env in ~/.bashrc (user indicated system vars there). Migrate from ~/.profile if present.
PROFILE_FILE=~/.profile
BASHRC_FILE=~/.bashrc

# If old block exists in .profile but not in .bashrc, remove it from .profile after migration.
if grep -q "# BEGIN JAVA ENV" "$PROFILE_FILE" && ! grep -q "# BEGIN JAVA ENV" "$BASHRC_FILE"; then
    echo "Migrating JAVA env block from .profile to .bashrc";
    # Extract JAVA_HOME line to recompute
    sed -n '/# BEGIN JAVA ENV/,/# END JAVA ENV/p' "$PROFILE_FILE" >> "$BASHRC_FILE"
    # Remove the block from .profile
    sed -i '/# BEGIN JAVA ENV/,/# END JAVA ENV/d' "$PROFILE_FILE"
fi

# Ensure block exists in .bashrc
if ! grep -q "# BEGIN JAVA ENV" "$BASHRC_FILE"; then
    cat <<EOL >> "$BASHRC_FILE"
# BEGIN JAVA ENV
export JAVA_HOME=$JAVA_HOME_DIR
# Ensure JAVA_HOME/bin in PATH only once
case :\$PATH: in
    *:"$JAVA_HOME_DIR"/bin:*) ;;
    *) export PATH=\$PATH:\$JAVA_HOME/bin ;;
esac
# END JAVA ENV
EOL
else
    # Update JAVA_HOME line in existing block
    sed -i "s|^export JAVA_HOME=.*|export JAVA_HOME=$JAVA_HOME_DIR|" "$BASHRC_FILE"
    # Ensure PATH line includes JAVA_HOME/bin
    if ! grep -E "PATH=.*$JAVA_HOME_DIR/bin" "$BASHRC_FILE" >/dev/null; then
        # Insert PATH update after JAVA_HOME line inside block
        awk -v jhome="$JAVA_HOME_DIR" 'BEGIN{inblock=0} {
            if($0 ~ /# BEGIN JAVA ENV/) inblock=1;
            if(inblock && $0 ~ /export JAVA_HOME=/){print;print "case :\"$PATH\": in";print "  *:" jhome "/bin:*) ;;";print "  *) export PATH=$PATH:" jhome "/bin ;;";print "esac";next}
            if($0 ~ /# END JAVA ENV/) inblock=0; print
        }' "$BASHRC_FILE" > "$BASHRC_FILE.tmp" && mv "$BASHRC_FILE.tmp" "$BASHRC_FILE"
    fi
fi

# Source .bashrc for current shell
source "$BASHRC_FILE"

# Ensure OpenSSH server present (install if missing)
if ! dpkg -s openssh-server >/dev/null 2>&1; then
    sudo apt-get install -y openssh-server
fi

# Start the SSH service if not running
if ! pgrep -x "sshd" >/dev/null; then
    sudo service ssh start
fi

# Generate SSH key pair if not already present
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -q -N ""
fi

# Copy the public key to authorized keys
if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys 2>/dev/null; then
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
fi

# Test SSH access
ssh -o StrictHostKeyChecking=no localhost exit

echo "Java ($JAVA_VERSION) installation/verification and SSH setup complete. JAVA_HOME=$JAVA_HOME_DIR"
