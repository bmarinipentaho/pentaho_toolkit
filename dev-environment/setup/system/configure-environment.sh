#!/bin/bash
# Configure Pentaho environment (directories, variables, aliases)
set -euo pipefail

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLKIT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
source "$TOOLKIT_ROOT/shared/lib/common.sh"

header "⚙️  Pentaho Environment Configuration"

check_not_root

subheader "Creating Pentaho Directories"

PENTAHO_DIRS=(
    "$HOME/pentaho"
    "$HOME/pentaho/configs"
    "$HOME/pentaho/keytabs"
    "$HOME/pentaho/certs"
    "$HOME/pentaho/logs"
    "$HOME/pentaho/scripts"
)

for dir in "${PENTAHO_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        success "Created: $dir"
    else
        log "Already exists: $dir"
    fi
done

subheader "Configuring Environment Variables"

# Add environment variables to ~/.bashrc
if ! /bin/grep -q "# Pentaho Environment Variables" ~/.bashrc; then
    log "Adding Pentaho environment variables to ~/.bashrc..."
    cat >> ~/.bashrc << 'EOF'

# Pentaho Environment Variables
export PENTAHO_HOME=~/pentaho
export PENTAHO_JAVA_HOME=$JAVA_HOME
export KRB5_CONFIG=/etc/krb5.conf

# Hadoop client settings (uncomment and set paths when you install Hadoop client)
# export HADOOP_HOME=/path/to/hadoop
# export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
# export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

# Spark settings (uncomment and set paths when you install Spark client)
# export SPARK_HOME=/path/to/spark
# export PATH=$SPARK_HOME/bin:$PATH

EOF
    success "Environment variables added to ~/.bashrc"
else
    success "Environment variables already configured in ~/.bashrc"
fi

subheader "Configuring Shell Aliases"

# Add useful aliases
if ! /bin/grep -q "# Pentaho Testing Aliases" ~/.bashrc; then
    log "Adding Pentaho aliases to ~/.bashrc..."
    cat >> ~/.bashrc << 'EOF'

# Pentaho Testing Aliases
# Modern command replacements (only if tools are available)
if command -v eza &> /dev/null; then
    alias ls='eza --color=always --group-directories-first'
    alias ll='eza -la --color=always --group-directories-first'
    alias la='eza -a --color=always --group-directories-first'
    alias lt='eza -aT --color=always --group-directories-first'
fi

if command -v batcat &> /dev/null; then
    alias cat='batcat'
elif command -v bat &> /dev/null; then
    alias cat='bat'
fi

if command -v fd &> /dev/null; then
    alias find='fd'
fi

if command -v rg &> /dev/null; then
    alias grep='rg'
fi

# Docker management aliases
alias docker-clean='docker system prune -f'
alias docker-stop-all='docker stop $(docker ps -q)'
alias docker-logs='docker-compose logs -f'

# Pentaho-specific aliases
alias kinit-dev='kinit devuser@PENTAHOQA.COM'
alias klist-check='klist -t'
alias pentaho-logs='cd ~/pentaho/logs'
alias pentaho-configs='cd ~/pentaho/configs'

# System monitoring aliases
alias top='htop'
alias du='ncdu'
alias ps='ps auxf'

# Network and debugging aliases
alias ports='netstat -tulanp'
alias myip='curl -s https://ipecho.net/plain; echo'

EOF
    success "Aliases added to ~/.bashrc"
else
    success "Aliases already configured in ~/.bashrc"
fi

success "Environment configuration completed"
echo ""
log "Changes will take effect after:"
log "  - New terminal sessions, or"
log "  - Running: source ~/.bashrc"
