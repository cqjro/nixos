#!/usr/bin/env bash

set -e #exists script if there is an error

# Configuration
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"  # Adjust to your SSH key path
NIXOS_CONFIG_DIR="$HOME/.nixos"  # Where you want to store the config	
GITHUB_REPO="cqjro/nixos"  # your-username/your-repo
LOG_FILE="$NIXOS_CONFIG_DIR/.log/start.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging functions that work without terminal
log() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"
}

warn() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" >> "$LOG_FILE"
}

error() {
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_FILE"
}

# Function to show GUI notifications
notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "SSH/NixOS Sync" "$1"
    fi
}

# Setup GUI ssh askpass
setup_ssh_askpass() {
	# Set SSH_ASKPASS environment variable to use GUI prompting.
	# openssh-askpass ships its dialog (gtk-ssh-askpass) under libexec/, so it is
	# not on PATH — reference it through the system profile path instead.
	if [ -x "/run/current-system/sw/libexec/gtk-ssh-askpass" ]; then
		export SSH_ASKPASS="/run/current-system/sw/libexec/gtk-ssh-askpass"
		log "Using openssh-askpass (gtk-ssh-askpass) for GUI password prompting"
	else
		error "No supported GUI askpass program found. Please install openssh-askpass (gtk-ssh-askpass)"
		notify "Error: Please install openssh-askpass (gtk-ssh-askpass)"
		return 1
	fi

	# Required for SSH_ASKPASS to work
	export DISPLAY="${DISPLAY:-:0}"
	export SSH_ASKPASS_REQUIRE=force

	log "SSH_ASKPASS set to: $SSH_ASKPASS"
}
# Function to check if SSH agent is running
ensure_ssh_agent() {
	if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
		log "Starting SSH agent..."
		eval "$(ssh-agent -s)"

		# Save agent info for other applications
		echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.ssh/agent-info
		echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> ~/.ssh/agent-info
		chmod 600 ~/.ssh/agent-info
	else
		log "SSH agent is already running"
		# Load existing agent info if available
		if [ -f ~/.ssh/agent-info ]; then
			source ~/.ssh/agent-info
		fi
	fi
}

# Function to add SSH key with GUI prompt
add_ssh_key() {
	if ! ssh-add -l | grep -q "$SSH_KEY_PATH" 2>/dev/null; then
		log "Adding SSH key to agent..."
		notify "Please enter SSH key passphrase"

		# Use setsid to detach from any controlling terminal
		if setsid ssh-add "$SSH_KEY_PATH" < /dev/null; then
			log "SSH key added successfully"
			notify "SSH key loaded successfully"
			return 0
		else
			error "Failed to add SSH key"
			notify "Failed to load SSH key"
			return 1
		fi
	else
		log "SSH key already loaded in agent"
		return 0
	fi
}

# The GitHub connection test and the stash/pull/stash-pop config sync moved to
# modules/scripts/config-sync.sh so they can also be run manually via the
# `config-sync` zsh alias (start.sh just delegates to it).

# Main execution
main() {
    log "Starting SSH and NixOS configuration sync..."
    
    # Wait a moment for the desktop environment to fully load
    sleep 2
    
    # Check if SSH key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        error "SSH key not found at $SSH_KEY_PATH"
        notify "Error: SSH key not found at $SSH_KEY_PATH"
        exit 1
    fi
    
    # Setup GUI password prompting
    if ! setup_ssh_askpass; then
        exit 1
    fi
    
    # Ensure SSH agent is running
    ensure_ssh_agent
    
    # Add SSH key to agent (this will show GUI prompt if needed)
    if add_ssh_key; then
        # Sync NixOS configuration (GitHub test + stash/pull/stash-pop,
        # defined in modules/scripts/config-sync.sh)
        if "$NIXOS_CONFIG_DIR/modules/scripts/config-sync.sh"; then
            log "Startup script completed successfully!"
            notify "SSH and NixOS sync completed successfully"
						exit 0
        else
            error "Config sync failed"
            notify "Warning: Config sync failed - check logs"
						exit 1
        fi
    else
        error "Failed to add SSH key, skipping configuration sync"
        notify "Error: Failed to load SSH key"
        exit 1
    fi
}

# Run main function in background to not block startup
main "$@"
