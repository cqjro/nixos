#!/usr/bin/env bash

# Inspired by the script from the noboilerplate video
#
#   rebuild.sh                        interactive: pick host -> diff -> commit -> rebuild -> push
#   rebuild.sh build  HOST            unprivileged build + closure diff (no root, no commit)
#   rebuild.sh switch HOST -m MSG     switch, then commit with generation metadata (no push)
#                     [--target USER@IP]   deploy to another machine (needs a terminal)
#   rebuild.sh push                   git push origin master
#
# The stages exist so an AI agent can drive a rebuild without answering prompts:
# `build` needs no privileges, `switch` asks for the sudo password through a GUI
# askpass dialog when there is no terminal (so a human still approves it), and
# `push` is separate so publishing is its own decision.
set -e # exits the script if there is any error
# cd to your config dir
cd ~/.nixos

LOG_DIR=".log"
mkdir -p "$LOG_DIR"

usage() {
    sed -n '5,9p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
    echo "$*" >&2
    exit 1
}

host_list() {
    find "$HOME/.nixos/modules/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

require_host() {
    host_list | grep -qx -- "$1" || die "Unknown host '$1'. Known hosts: $(host_list | tr '\n' ' ')"
}

# nixos-rebuild renamed its remote sudo flags; pick the pair this version knows
elevate_flags() {
    if nixos-rebuild --help 2>&1 | grep -q -- '--elevate'; then
        echo "--elevate sudo --ask-elevate-password"
    else
        echo "--use-remote-sudo --ask-sudo-password"
    fi
}

# sudo that falls back to a GUI askpass dialog when there is no terminal
# (agent shells), so the password is always typed by a human.
as_root() {
    if [ -t 0 ]; then
        sudo "$@"
    else
        local askpass=/run/current-system/sw/libexec/gtk-ssh-askpass
        [ -x "$askpass" ] || die "No terminal and no askpass at $askpass; run this from a terminal."
        : "${DISPLAY:=:0}"
        export DISPLAY
        SUDO_ASKPASS="$askpass" sudo -A "$@"
    fi
}

# run_logged LOGFILE CMD...
# On a terminal: live-stream with syntax highlighting (bat) while keeping a full
# log. Without one (agent shells): log only, so the output stays small.
# On failure surface only the relevant errors.
run_logged() {
    local logfile=$1 status
    shift
    set +e
    if [ -t 1 ]; then
        "$@" 2>&1 | tee "$logfile" | bat --paging=never --decorations=never --language=log
        status=${PIPESTATUS[0]}
    else
        "$@" >"$logfile" 2>&1
        status=$?
    fi
    set -e
    if [ "$status" -ne 0 ]; then
        echo "Build failed. Relevant errors (full log: $logfile):"
        grep -i -C 4 -E -- 'error|failed|fail|fatal' "$logfile" || true
        return 1
    fi
}

# Get current generation metadata (list-generations doesn't support --target-host,
# so for remote builds we run it over SSH on the target instead)
current_generation() {
    local remote=${1:-}
    if [ -n "$remote" ]; then
        ssh "$remote" "nixos-rebuild list-generations" | awk '$NF == "True"'
    else
        nixos-rebuild list-generations | awk '$NF == "True"'
    fi
}

# do_switch HOST [USER@IP]
do_switch() {
    local host=$1 remote=${2:-}
    local -a cmd flags
    git add --all # to ensure there isnt issues during build
    if [ -n "$remote" ]; then
        [ -t 0 ] || die "A remote switch needs a terminal for the sudo password; run ./rebuild.sh yourself."
        # Remote rebuild: no local sudo. nixos-rebuild SSHes out as the target user
        # and escalates privileges on the remote side.
        read -ra flags <<<"$(elevate_flags)"
        cmd=(nixos-rebuild switch --flake ".#$host" --impure --target-host "$remote" "${flags[@]}")
    else
        # Local rebuild: needs local sudo.
        cmd=(as_root nixos-rebuild switch --flake ".#$host" --impure)
    fi
    echo "NixOS Rebuilding..."
    run_logged "$LOG_DIR/nixos-switch.log" "${cmd[@]}" || exit 1
}

# Commit all changes with the generation metadata
# commit_with_metadata HOST GENERATION MESSAGE
commit_with_metadata() {
    git add --all
    if git diff --cached --quiet; then
        echo "No uncommitted changes; skipping commit."
        return 0
    fi
    git commit -m "$1: $2 || $3" || die "Failed to commit changes!"
}

push_changes() {
    git push origin master || die "Failed to push to remote repository!"
}

notify_ok() {
    echo "NixOS Rebuilt OK!"
    if command -v notify-send >/dev/null; then
        notify-send -e "NixOS Rebuilt OK! \n ${1}" --icon=software-update-available || true
    fi
}

cmd_build() {
    local host=${1:-}
    [ -n "$host" ] || die "usage: rebuild.sh build HOST"
    require_host "$host"
    git add --all # flakes only see tracked files
    run_logged "$LOG_DIR/nixos-build.log" nixos-rebuild build --flake ".#$host" --impure || exit 1
    if [ "$host" = "$(hostname)" ]; then
        nix store diff-closures /run/current-system ./result
    else
        echo "Built $host OK (a closure diff is only available for the local host)."
    fi
}

cmd_switch() {
    local host=${1:-} message="" remote="" current
    [ -n "$host" ] || die "usage: rebuild.sh switch HOST -m MESSAGE [--target USER@IP]"
    shift
    while [ $# -gt 0 ]; do
        case $1 in
            -m|--message) [ $# -ge 2 ] || die "$1 needs a value"; message=$2; shift 2 ;;
            --target) [ $# -ge 2 ] || die "$1 needs a value"; remote=$2; shift 2 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
    [ -n "$message" ] || die "switch needs -m MESSAGE (used in the commit)"
    require_host "$host"
    if [ "$host" != "$(hostname)" ] && [ -z "$remote" ]; then
        die "'$host' is not this machine ($(hostname)); pass --target USER@IP"
    fi
    do_switch "$host" "$remote"
    current=$(current_generation "$remote") || die "Failed to get current generation metadata!"
    commit_with_metadata "$host" "$current" "$message"
    notify_ok "$current"
}

cmd_push() {
    push_changes
}

cmd_interactive() {
    local dir message yn current target_user target_ip remote=""
    local -a dir_list
    # Get the list of directories and store them in an array
    mapfile -t dir_list < <(host_list)
    PS3="Please select a host: "
    select dir in "${dir_list[@]}"; do
        if [[ -n "$dir" ]]; then
            echo "You selected: $dir"
            break
        else
            echo "Invalid selection."
        fi
    done
    # Early return if no changes were detected (thanks @singiamtel!)
    # Compare against HEAD (not just the index): a failed attempt already ran
    # `git add --all`, so a staged-but-uncommitted tree would otherwise bail here.
    if git diff --quiet HEAD; then
        echo "No changes detected, exiting."
        exit 0
    fi
    # Autoformat your nix files
    # alejandra . &>/dev/null \
    #   || ( alejandra . ; echo "formatting failed!" && exit 1)
    # Shows your changes
    git diff -U0
    read -r -p "Please provide a commit message: " message
    echo "About to rebuild NixOS for host: $dir"
    while true; do
        read -r -p "Do you want to proceed? (y/n) " yn
        case $yn in
            [Yy]* ) echo "Proceeding..."; break;; # User entered 'y' or 'Y'
            [Nn]* ) echo "Exiting..."; exit;;     # User entered 'n' or 'N', script exits
            * ) echo "Invalid response. Please answer y or n.";; # Invalid input, prompt again
        esac
    done

    # Determine whether we're rebuilding locally or remotely
    if [[ "$(hostname)" != "$dir" ]]; then
        echo "Current hostname ('$(hostname)') differs from selected host ('$dir')."
        read -r -p "Enter target user: " target_user
        read -r -p "Enter target IP address: " target_ip
        remote="${target_user}@${target_ip}"
    fi

    do_switch "$dir" "$remote"
    current=$(current_generation "$remote") || die "Failed to get current generation metadata!"
    commit_with_metadata "$dir" "$current" "$message"
    push_changes
    notify_ok "$current"
}

case "${1:-}" in
    "")            cmd_interactive ;;
    build)         shift; cmd_build "$@" ;;
    switch)        shift; cmd_switch "$@" ;;
    push)          cmd_push ;;
    -h|--help|help) usage ;;
    *)             usage >&2; exit 1 ;;
esac
