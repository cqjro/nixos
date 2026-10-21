#!/usr/bin/env bash

# Syncs ~/.nixos from GitHub. Extract of the sync portion of start.sh so the
# config can be pulled from a terminal or when SSH'd into another host
# (e.g. REDRUM) — your SSH key needs to be loaded in an agent first
# (start.sh does this automatically on login).

# Configuration
NIXOS_CONFIG_DIR="${NIXOS_CONFIG_DIR:-$HOME/.nixos}"
LOG_FILE="$NIXOS_CONFIG_DIR/.log/config-sync.log"

# Ensure the log file exists
mkdir -p "$(dirname "$LOG_FILE")"

# Logging functions that work without a terminal
log() {
	printf '[%s] [INFO] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

warn() {
	printf '[%s] [WARN] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

error() {
	printf '[%s] [ERROR] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG_FILE"
}

# Function to show GUI notifications (only where a display exists)
notify() {
	if command -v notify-send >/dev/null 2>&1 && [ -n "$DISPLAY" ]; then
		notify-send "NixOS Config Sync" "$1"
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
sync_nixos_config() {
	log "Syncing NixOS configuration from GitHub..."

	if [ ! -d "$NIXOS_CONFIG_DIR" ]; then
		warn "Configuration directory $NIXOS_CONFIG_DIR does not exist"
		notify "Error: Configuration directory does not exist"
		return 1
	fi

	cd "$NIXOS_CONFIG_DIR"

	# Check if it's a git repository
	if [ ! -d ".git" ]; then
		warn "Directory exists but is not a git repository"
		notify "Error: Config directory is not a git repo"
		return 1
	fi

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

	log "NixOS configuration sync completed"
	return 0
}

# Main execution
main() {
	log "Starting NixOS configuration sync..."

	# Verify GitHub auth (non-fatal)
	test_github_connection

	# Sync the config
	if sync_nixos_config; then
		log "Config sync completed successfully!"
		notify "NixOS config sync completed successfully"
		return 0
	else
		error "Config sync failed"
		notify "Warning: Config sync failed - check logs"
		return 1
	fi
}

main "$@"
exit $?