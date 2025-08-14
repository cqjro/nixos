#!/user/bin/env bash

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
	# Set SSH_ASKPASS environment variable to use GUI prompting
	# if command -v ksshaskpass >/dev/null 2>&1; then
	# 	export SSH_ASKPASS="ksshaskpass"
	# 	log "Using ksshaskpass for GUI password prompting"
	if command -v ssh-askpass-fullscreen >/dev/null 2>&1; then
		export SSH_ASKPASS="ssh-askpass-fullscreen"
		log "Using ssh-askpass-fullscreen for GUI password prompting"
	else
		error "No supported GUI askpass program found. Please install ksshaskpass or ssh-askpass-fullscreen"
		notify "Error: Please install ksshaskpass or ssh-askpass-fullscreen"
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

# Function to test SSH connection to GitHub
test_github_connection() {
	log "Testing GitHub SSH connection..."
	if timeout 10 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
		log "GitHub SSH connection successful"
		return 0
	else
		warn "GitHub SSH connection failed, but continuing anyway..."
		return 1
	fi
}

# Function to sync NixOS configuration
# Function to sync NixOS configuration
sync_nixos_config() {
	log "Syncing NixOS configuration from GitHub..."

	if [ -d "$NIXOS_CONFIG_DIR" ]; then
		log "Configuration directory exists, syncing with stash/pull/stash pop..."
		cd "$NIXOS_CONFIG_DIR"

		# Check if it's a git repository
		if [ -d ".git" ]; then
			# Stash any local changes
			log "Stashing local changes..."
			if git diff --quiet && git diff --cached --quiet; then
				log "No local changes to stash"
				STASH_CREATED=false
			else
				if git stash push -m "Auto-stash before sync $(date)" 2>/dev/null; then
					log "Local changes stashed successfully"
					STASH_CREATED=true
				else
					warn "Failed to stash local changes"
					STASH_CREATED=false
				fi
			fi

			# Pull latest changes
			log "Pulling latest changes from remote..."
			if timeout 30 git pull origin master 2>/dev/null; then
				log "Git pull completed successfully"

				# Pop stash if we created one
				if [ "$STASH_CREATED" = true ]; then
					log "Restoring stashed changes..."
					if git stash pop 2>/dev/null; then
						log "Stashed changes restored successfully"
						notify "NixOS config updated (local changes preserved)"
					else
						warn "Failed to restore stashed changes - you may need to resolve conflicts manually"
						notify "NixOS config updated - check for stash conflicts"
					fi
				else
					notify "NixOS configuration updated"
				fi
			else
				warn "Failed to pull changes from remote repository"

				# If we stashed changes but pull failed, try to restore them
				if [ "$STASH_CREATED" = true ]; then
					log "Attempting to restore stashed changes after failed pull..."
					git stash pop 2>/dev/null || warn "Failed to restore stashed changes"
				fi

				notify "Warning: Failed to update NixOS config"
				return 1
			fi
		else
			warn "Directory exists but is not a git repository"
			notify "Error: Config directory is not a git repo"
			return 1
		fi
	fi

	log "NixOS configuration sync completed"
}

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
        # Test GitHub connection
        test_github_connection
        
        # Sync NixOS configuration
        if sync_nixos_config; then
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
