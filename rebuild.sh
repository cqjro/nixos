#!/usr/bin/env bash

# Inspired by the script from the noboilerplate video
#
#   rebuild.sh                                     interactive: pick host -> diff -> build -> commit -> switch (master) or test (branch) -> push
#   rebuild.sh check [HOST...]                     tier-0 checks: script syntax, tracked secrets/firmware, whitespace, registry sync, eval
#   rebuild.sh eval HOST                           evaluate only (prints the drvPath, builds nothing)
#   rebuild.sh build HOST                          unprivileged build + closure diff (no root, no commit)
#   rebuild.sh test HOST [--target USER@IP]        activate without recording a generation; a reboot reverts it
#   rebuild.sh dry HOST [--target USER@IP]         dry-activate: show what a switch would restart
#   rebuild.sh revert                              re-activate the recorded generation after a test
#   rebuild.sh switch HOST [-m MSG] [--target USER@IP]   master only: fast-forward to origin/master, commit a dirty tree with MSG, then switch
#   rebuild.sh push                                push the current branch to origin (never forced)
#   rebuild.sh generations [--target USER@IP]      list generations with the commit each was built from
#
# The stages exist so an AI agent can drive a rebuild without answering prompts:
# `check`/`eval`/`build` need no privileges; `test`/`dry`/`revert`/`switch` ask
# for the sudo password through a GUI askpass dialog when there is no terminal
# (so a human still approves them); `push` is separate so publishing is its own
# decision. Only `switch` records a generation, and only from master, so every
# generation maps to merged work via system.configurationRevision
# (modules/essentials/config-revision.nix).
set -e # exits the script if there is any error

# Work on the checkout this script belongs to (worktree-safe). The `rebuild` zsh
# alias runs a copy from the Nix store, so fall back to the current directory's
# checkout, then to ~/.nixos.
repo_root() {
    local dir top
    for dir in "$(dirname "$(readlink -f "$0")")" "$PWD"; do
        top=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || continue
        [ -d "$top/modules/hosts" ] && { echo "$top"; return; }
    done
    echo "$HOME/.nixos"
}
cd "$(repo_root)"

LOG_DIR=".log"
mkdir -p "$LOG_DIR"

usage() {
    sed -n 's/^#   \(rebuild\.sh.*\)/\1/p' "$0"
}

die() {
    echo "$*" >&2
    exit 1
}

host_list() {
    find modules/hosts -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

require_host() {
    host_list | grep -qx -- "$1" || die "Unknown host '$1'. Known hosts: $(host_list | tr '\n' ' ')"
}

current_branch() {
    git rev-parse --abbrev-ref HEAD
}

tree_dirty() {
    git add --all # flakes only see tracked files
    ! git diff --cached --quiet HEAD
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

# parse_target ARGS... -> sets $remote (and $message for -m)
parse_opts() {
    remote="" message=""
    while [ $# -gt 0 ]; do
        case $1 in
            -m|--message) [ $# -ge 2 ] || die "$1 needs a value"; message=$2; shift 2 ;;
            --target) [ $# -ge 2 ] || die "$1 needs a value"; remote=$2; shift 2 ;;
            *) die "Unknown option: $1" ;;
        esac
    done
}

# Get current generation metadata (list-generations doesn't support --target-host,
# so for remote builds we run it over SSH on the target instead)
list_generations_json() {
    local remote=${1:-}
    if [ -n "$remote" ]; then
        ssh "$remote" "nixos-rebuild list-generations --json"
    else
        nixos-rebuild list-generations --json
    fi
}

current_generation() {
    list_generations_json "${1:-}" | jq -r '.[] | select(.current) | "\(.generation) (\(.configurationRevision[0:12]))"'
}

# activate ACTION HOST [USER@IP]   ACTION: switch | test | dry-activate
activate() {
    local action=$1 host=$2 remote=${3:-}
    local -a cmd flags
    git add --all # to ensure there isnt issues during build
    if [ "$host" != "$(hostname)" ] && [ -z "$remote" ]; then
        die "'$host' is not this machine ($(hostname)); pass --target USER@IP"
    fi
    if [ -n "$remote" ]; then
        [ -t 0 ] || die "A remote $action needs a terminal for the sudo password; run ./rebuild.sh yourself."
        # Remote rebuild: no local sudo. nixos-rebuild SSHes out as the target user
        # and escalates privileges on the remote side.
        read -ra flags <<<"$(elevate_flags)"
        cmd=(nixos-rebuild "$action" --flake ".#$host" --target-host "$remote" "${flags[@]}")
    else
        # Local rebuild: needs local sudo.
        cmd=(as_root nixos-rebuild "$action" --flake ".#$host")
    fi
    echo "NixOS: $action $host..."
    run_logged "$LOG_DIR/nixos-$action.log" "${cmd[@]}" || exit 1
}

build_host() {
    run_logged "$LOG_DIR/nixos-build.log" nixos-rebuild build --flake ".#$1"
}

# switch records a generation, so it only runs from master: try branches with `test`.
# It also brings master up to date (fetch + fast-forward) so a switch always builds
# the latest merged work; nothing pulls in the background any more.
require_master() {
    local branch
    branch=$(current_branch)
    [ "$branch" = master ] || die "switch records a generation, so it only runs on master (this is '$branch'). Use './rebuild.sh test HOST' to try a branch, or merge its PR first."
    if ! GIT_TERMINAL_PROMPT=0 timeout 30 git fetch --quiet origin master; then
        echo "Warning: could not fetch origin/master; using the local master as it is." >&2
        return 0
    fi
    git merge-base --is-ancestor origin/master HEAD && return 0 # up to date (or ahead)
    git merge-base --is-ancestor HEAD origin/master \
        || die "master and origin/master have diverged; reconcile them by hand before switching."
    ! tree_dirty || die "origin/master has new commits and this checkout has uncommitted changes; move the changes to a branch before switching."
    git merge --ff-only --quiet origin/master || die "Failed to fast-forward master to origin/master!"
    echo "Fast-forwarded master to $(git log -1 --format='%h %s')."
}

commit_all() {
    git add --all
    git commit -m "$1" || die "Failed to commit changes!"
}

push_changes() {
    local branch
    branch=$(current_branch)
    [ "$branch" != HEAD ] || die "Detached HEAD; check out a branch before pushing."
    if [ "$branch" = master ] && [ ! -t 0 ]; then
        die "Agents push branches, not master; master changes land by merging a PR."
    fi
    git push -u origin "$branch" || die "Failed to push to remote repository!"
}

notify_ok() {
    echo "NixOS Rebuilt OK! ${1}"
    if command -v notify-send >/dev/null; then
        notify-send -e "NixOS Rebuilt OK! \n ${1}" --icon=software-update-available || true
    fi
}

cmd_check() {
    local -a hosts scripts
    local host base changed out fail=0
    if [ $# -gt 0 ]; then
        hosts=("$@")
        for host in "${hosts[@]}"; do require_host "$host"; done
    else
        mapfile -t hosts < <(host_list)
    fi
    git add --all # flakes only see tracked files

    echo "== script syntax"
    mapfile -t scripts < <(git ls-files '*.sh')
    for f in "${scripts[@]}"; do
        bash -n "$f" || { echo "FAIL: $f"; fail=1; }
    done

    echo "== tracked secrets / firmware"
    if out=$(git ls-files | grep -Ei '(^|/)firmware/|(^|/)(token|client_secret)\.json$|modules/server/youtube/config\.json$|(^|/)[^/]*\.env$|\.(pem|key)$'); then
        echo "FAIL: these must never be committed:"; echo "$out"; fail=1
    fi

    echo "== whitespace / conflict markers"
    base=$(git merge-base HEAD origin/master 2>/dev/null || git rev-parse HEAD)
    git diff --cached --check "$base" || fail=1

    echo "== upstream registry rows (README.md vs docs/agents/upstream-registry.md)"
    registry_rows() { sed -n '/^##\{0,1\} Pending upstream fixes/,/^## [^P]/p' "$1" | grep -oE '^\| [0-9]+ \|' | tr -dc '0-9\n' | sort -n | tr '\n' ' '; }
    if [ "$(registry_rows README.md)" != "$(registry_rows docs/agents/upstream-registry.md)" ]; then
        echo "FAIL: rows differ: README [$(registry_rows README.md)] vs registry [$(registry_rows docs/agents/upstream-registry.md)]"; fail=1
    fi

    changed=$(git diff --cached --name-only "$base")
    if echo "$changed" | grep -qE '^(modules/|flake\.nix|rebuild\.sh)' && ! echo "$changed" | grep -qE '^(README\.md|AGENTS\.md|docs/)'; then
        echo "note: config changed but no README.md/AGENTS.md/docs change — confirm none is needed."
    fi

    for host in "${hosts[@]}"; do
        echo "== eval $host"
        if ! out=$(nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath" 2>&1); then
            echo "FAIL: $(echo "$out" | grep -E '^ *error:' | tail -1 | sed 's/^ *//') (full: nix eval .#nixosConfigurations.$host.config.system.build.toplevel.drvPath)"; fail=1
        fi
    done
    [ "$fail" -eq 0 ] && echo "All checks passed." || { echo "Some checks failed."; return 1; }
}

cmd_eval() {
    local host=${1:-}
    [ -n "$host" ] || die "usage: rebuild.sh eval HOST"
    require_host "$host"
    git add --all # flakes only see tracked files
    nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
    echo
}

cmd_build() {
    local host=${1:-}
    [ -n "$host" ] || die "usage: rebuild.sh build HOST"
    require_host "$host"
    git add --all # flakes only see tracked files
    build_host "$host" || exit 1
    if [ "$host" = "$(hostname)" ]; then
        nix store diff-closures /run/current-system ./result
    else
        echo "Built $host OK (a closure diff is only available for the local host)."
    fi
}

# cmd_activate ACTION HOST [--target USER@IP]   (test | dry-activate)
cmd_activate() {
    local action=$1 host=${2:-}
    [ -n "$host" ] || die "usage: rebuild.sh ${action%-activate} HOST [--target USER@IP]"
    shift 2
    parse_opts "$@"
    require_host "$host"
    activate "$action" "$host" "$remote"
    if [ "$action" = test ]; then
        echo "Activated $host without recording a generation; './rebuild.sh revert' or a reboot returns to the recorded one."
    fi
}

cmd_revert() {
    as_root /nix/var/nix/profiles/system/bin/switch-to-configuration test
    echo "Re-activated the recorded generation: $(current_generation)"
}

cmd_switch() {
    local host=${1:-} current
    [ -n "$host" ] || die "usage: rebuild.sh switch HOST [-m MESSAGE] [--target USER@IP]"
    shift
    parse_opts "$@"
    require_host "$host"
    require_master
    if tree_dirty; then
        [ -n "$message" ] || die "Uncommitted changes: pass -m MESSAGE to commit them before switching."
        build_host "$host" || exit 1 # fail before committing
        commit_all "$message"
    fi
    activate switch "$host" "$remote"
    current=$(current_generation "$remote") || { echo "Warning: switched, but could not read the generation number (check with ./rebuild.sh generations)." >&2; current="?"; }
    notify_ok "$host generation $current"
}

cmd_push() {
    push_changes
}

cmd_generations() {
    local host gen date rev cur subject base
    parse_opts "$@"
    host=$(if [ -n "$remote" ]; then ssh "$remote" hostname; else hostname; fi)
    list_generations_json "$remote" |
        jq -r '.[] | [.generation, .date, .configurationRevision, (if .current then "*" else " " end)] | @tsv' |
        while IFS=$'\t' read -r gen date rev cur; do
            case $rev in
                Unknown|"")
                    # older generations: recorded by the old post-switch commit "HOST: GEN … || MESSAGE"
                    subject=$(git log --all -1 --format=%s -E --grep="^$host: $gen " | sed 's/.*|| //')
                    rev="-"
                    [ -n "$subject" ] || subject="(no revision recorded)"
                    ;;
                *)
                    base=${rev%-dirty}
                    subject=$(git log -1 --format=%s "$base" 2>/dev/null) || subject="(commit not in this clone; git fetch)"
                    [ "$rev" = "$base" ] || subject="$subject [+ uncommitted changes]"
                    rev=${base:0:7}
                    ;;
            esac
            printf '%s %-5s %s  %-7s  %s\n' "$cur" "$gen" "$date" "$rev" "$subject"
        done
}

cmd_interactive() {
    local dir message yn branch target_user target_ip remote="" action current
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
    # On master a rebuild records a generation (switch); on any other branch it
    # only test-activates, so unmerged work never becomes a generation.
    branch=$(current_branch)
    if [ "$branch" = master ]; then action=switch; else action=test; fi
    echo "Branch: $branch -> $action"
    if [ "$action" = switch ]; then
        require_master
    fi

    if tree_dirty; then
        # Autoformat your nix files
        # alejandra . &>/dev/null \
        #   || ( alejandra . ; echo "formatting failed!" && exit 1)
        # Shows your changes
        git diff --cached -U0 HEAD
        read -r -p "Please provide a commit message: " message
    else
        echo "No uncommitted changes; HEAD is $(git log -1 --format='%h %s')."
    fi
    echo "About to $action NixOS for host: $dir"
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

    if [ -n "$message" ]; then
        build_host "$dir" || exit 1 # fail before committing
        commit_all "$message"
    fi
    activate "$action" "$dir" "$remote"
    if [ "$action" = switch ]; then
        current=$(current_generation "$remote") || { echo "Warning: switched, but could not read the generation number (check with ./rebuild.sh generations)." >&2; current="?"; }
        current="generation $current"
    else
        current="test-activated $branch (no generation recorded)"
    fi
    push_changes
    notify_ok "$dir $current"
}

case "${1:-}" in
    "")            cmd_interactive ;;
    check)         shift; cmd_check "$@" ;;
    eval)          shift; cmd_eval "$@" ;;
    build)         shift; cmd_build "$@" ;;
    test)          shift; cmd_activate test "$@" ;;
    dry)           shift; cmd_activate dry-activate "$@" ;;
    revert)        cmd_revert ;;
    switch)        shift; cmd_switch "$@" ;;
    push)          cmd_push ;;
    generations)   shift; cmd_generations "$@" ;;
    -h|--help|help) usage ;;
    *)             usage >&2; exit 1 ;;
esac
