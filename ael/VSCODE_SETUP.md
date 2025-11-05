# VS Code Setup for AEL Automation Development

This document describes the VS Code setup for working with the AEL automation project on a new VM.

## Required Extensions

### Essential
- **GitHub Copilot** (`GitHub.copilot`)
  - AI pair programmer used throughout development
- **GitHub Copilot Chat** (`GitHub.copilot-chat`)
  - AI assistant for code explanations and troubleshooting

### Recommended for Shell Scripting
- **shellcheck** (`timonwong.shellcheck`)
  - Bash script linting
- **Bash IDE** (`mads-hartmann.bash-ide-vscode`)
  - Bash language server

### Optional but Helpful
- **GitLens** (`eamodio.gitlens`)
  - Enhanced Git integration
- **Markdown All in One** (`yzhang.markdown-all-in-one`)
  - Better markdown editing for README and docs

## Installation Steps

### 1. Install VS Code
```bash
# On Ubuntu 22.04/24.04
sudo snap install --classic code
# OR download from https://code.visualstudio.com/
```

### 2. Install Extensions via Command Line
```bash
code --install-extension GitHub.copilot
code --install-extension GitHub.copilot-chat
code --install-extension timonwong.shellcheck
code --install-extension mads-hartmann.bash-ide-vscode
code --install-extension eamodio.gitlens
code --install-extension yzhang.markdown-all-in-one
```

### 3. Configure GitHub Copilot
After installation:
1. Open VS Code
2. Sign in to GitHub when prompted
3. Authorize GitHub Copilot

## VS Code Settings

Recommended `settings.json` additions for this project:

```json
{
  "files.eol": "\n",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "shellcheck.enable": true,
  "shellcheck.run": "onSave",
  "[shellscript]": {
    "editor.defaultFormatter": "foxundermoon.shell-format",
    "editor.formatOnSave": false
  },
  "terminal.integrated.defaultProfile.linux": "bash"
}
```

## Project Setup on New VM

### 1. Prerequisites
```bash
# Install Git
sudo apt update
sudo apt install -y git

# Install GitHub CLI (recommended)
sudo snap install gh
gh auth login
```

### 2. Clone Repository
```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/bmarinipentaho/ael-automation.git
cd ael-automation
```

### 3. Make Scripts Executable
```bash
chmod -R +x .
```

### 4. Open in VS Code
```bash
code .
```

## Quick Start After Setup

Once you have VS Code configured and the repository cloned:

```bash
cd ~/projects/ael-automation

# View help
./deploy_ael.sh --help

# Deploy with local PDI artifacts
./deploy_ael.sh /path/to/pdi-client.zip /path/to/spark-addon.zip

# Deploy with libwebkit for full PDI client support
./deploy_ael.sh --install-libwebkit /path/to/pdi-client.zip /path/to/spark-addon.zip
```

## Troubleshooting

### ShellCheck Not Working
```bash
# Install shellcheck system-wide
sudo apt install shellcheck
```

### Copilot Not Activating
1. Check subscription at https://github.com/settings/copilot
2. Sign out and sign back in to VS Code
3. Reload VS Code window (Ctrl+Shift+P → "Developer: Reload Window")

### Git Authentication Issues
```bash
# Use GitHub CLI for easier auth
gh auth login

# Or configure SSH keys
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add key to GitHub: https://github.com/settings/keys
```

## Development Workflow

1. Make changes to scripts
2. Test locally: `./deploy_ael.sh ...`
3. Commit changes: `git add . && git commit -m "message"`
4. Push to GitHub: `git push`
5. Clean environment: `./remove_ael.sh --purge-hdfs --purge-pdi --force`
6. Redeploy to verify

## Notes

- All scripts use `#!/bin/bash` shebang
- Set `-e` (exit on error) and `-x` (debug output) are standard
- Environment variables are persisted to both `~/.bashrc` and `~/.profile`
- The project uses `hadoop fs` instead of `hdfs dfs` for better portability
