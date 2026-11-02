#!/usr/bin/env bash
# agent-notify: deterministic Claude Code hook -> ntfy + notify-send bridge.
# No LLM, no network except the optional ntfy POST. Wired up by
# modules/home-manager/ai-tools/notifications.nix; documented in
# docs/notifications.md.
#
# Usage (as a hook):  agent-notify            # hook JSON on stdin
#        (manual):    agent-notify test [approval|finished|failed]
#
# Config dir (created by the human, never in the repo):
#   $AGENT_NOTIFY_DIR or $XDG_CONFIG_HOME/agent-notify or ~/.config/agent-notify
#     topic         ntfy topic (secret when using ntfy.sh); absent -> no push
#     server        ntfy base URL, default https://ntfy.sh
#     token         optional ntfy access token (Authorization: Bearer)
#     quiet-hours   optional "HH:MM-HH:MM" (may wrap midnight)
#     include-text  if present, completion pushes carry the agent's last words
#     debug         if present, also dump raw hook payloads to the state dir
#
# A hook must never break the agent: every path exits 0.

set -u

cfg="${AGENT_NOTIFY_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/agent-notify}"
state="${XDG_STATE_HOME:-$HOME/.local/state}/agent-notify"
dedupe_secs="${AGENT_NOTIFY_DEDUPE_SECS:-30}"
mkdir -p "$state" 2>/dev/null || exit 0

log() {
	# one line per decision: this is the evidence for "did the hook fire"
	printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$state/events.log" 2>/dev/null
	if [ -f "$state/events.log" ] && [ "$(stat -c %s "$state/events.log")" -gt 204800 ]; then
		tail -n 500 "$state/events.log" >"$state/events.log.tmp" && mv "$state/events.log.tmp" "$state/events.log"
	fi
}

if [ "${1:-}" = "send" ]; then
	# non-hook callers (rebuild.sh): agent-notify send KIND MESSAGE
	# KIND = approval|finished|failed|info; AGENT_NOTIFY_LABEL overrides the heading.
	# info is a low-priority notice: no desktop popup, never dropped by quiet hours.
	# The message is caller-supplied (not agent output), so it goes to ntfy too.
	# The session id is a hash of kind+label+message, so an identical notice
	# inside the dedupe window collapses to one.
	force_text=1
	case "${2:-finished}" in
	approval) ev=Notification ;;
	failed) ev=StopFailure ;;
	info) ev=AgentNotifyInfo ;;
	*) ev=Stop ;;
	esac
	sid=$(printf '%s|%s|%s' "${2:-finished}" "${AGENT_NOTIFY_LABEL:-}" "${3:-}" | sha1sum | cut -c1-16)
	payload=$(jq -nc --arg ev "$ev" --arg m "${3:-}" --arg cwd "$PWD" --arg s "send-$sid" \
		'{hook_event_name: $ev, notification_type: "permission_prompt", message: $m, last_assistant_message: $m, error: $m, cwd: $cwd, session_id: $s}')
elif [ "${1:-}" = "test" ]; then
	case "${2:-approval}" in
	approval) payload='{"hook_event_name":"Notification","notification_type":"permission_prompt","message":"Claude needs your permission to use Bash","session_id":"selftest-approval"}' ;;
	failed) payload='{"hook_event_name":"StopFailure","error":"rate_limit","session_id":"selftest-failed"}' ;;
	*) payload='{"hook_event_name":"Stop","last_assistant_message":"Test completion","session_id":"selftest-done"}' ;;
	esac
	payload=$(printf '%s' "$payload" | jq -c --arg cwd "$PWD" '. + {cwd: $cwd}')
	# a manual test should never be eaten by dedupe
	rm -f "$state"/dedupe-selftest-* 2>/dev/null
else
	payload=$(cat)
fi

[ -n "$payload" ] || exit 0
[ -f "$cfg/debug" ] && printf '%s\n' "$payload" >>"$state/payloads.jsonl"

field() { printf '%s' "$payload" | jq -r "$1 // empty" 2>/dev/null; }

event=$(field .hook_event_name)
ntype=$(field .notification_type)
cwd=$(field .cwd)
session=$(field .session_id)
[ -n "$session" ] || session=unknown

# The generic permission_prompt Notification carries no command; the
# PermissionRequest hook does. Let the generic one wait so that one wins the
# dedupe race.
[ "$event:$ntype" = "Notification:permission_prompt" ] && sleep 2

# classify; anything not listed is logged and dropped
kind=""
case "$event:$ntype" in
Notification:permission_prompt | Notification:elicitation_dialog | Notification:agent_needs_input | PermissionRequest:*) kind=approval ;;
Stop:*)
	# a Stop re-fired by a Stop hook is not a new completion
	[ "$(field .stop_hook_active)" = "true" ] || kind=finished
	;;
StopFailure:*) kind=failed ;;
AgentNotifyInfo:*) kind=info ;;
esac
if [ -z "$kind" ]; then
	log "event=$event type=$ntype session=$session action=ignored"
	exit 0
fi

# dedupe: the same (session, kind) inside the window is one notification.
# PermissionRequest + Notification for the same prompt collapse here too.
stamp="$state/dedupe-$session-$kind"
now_s=$(date +%s)
if [ -f "$stamp" ] && [ $((now_s - $(stat -c %Y "$stamp"))) -lt "$dedupe_secs" ]; then
	log "event=$event type=$ntype session=$session kind=$kind action=deduped"
	exit 0
fi
: >"$stamp"
find "$state" -name 'dedupe-*' -mmin +60 -delete 2>/dev/null

in_quiet() {
	local spec s e now
	[ -r "$cfg/quiet-hours" ] || return 1
	spec=$(tr -d '[:space:]' <"$cfg/quiet-hours")
	[[ $spec =~ ^([0-9]{2}):([0-9]{2})-([0-9]{2}):([0-9]{2})$ ]] || return 1
	s=$((10#${BASH_REMATCH[1]} * 60 + 10#${BASH_REMATCH[2]}))
	e=$((10#${BASH_REMATCH[3]} * 60 + 10#${BASH_REMATCH[4]}))
	now=$((10#$(date +%H) * 60 + 10#$(date +%M)))
	if [ "$s" -le "$e" ]; then
		[ "$now" -ge "$s" ] && [ "$now" -lt "$e" ]
	else
		[ "$now" -ge "$s" ] || [ "$now" -lt "$e" ]
	fi
}

quiet=0
in_quiet && quiet=1

# title: host - worktree/repo (branch), so you know which machine and thread
host=$(cat /proc/sys/kernel/hostname 2>/dev/null || echo unknown-host)
where=${cwd:-$PWD}
repo=$(basename "$(git -C "$where" rev-parse --show-toplevel 2>/dev/null || echo "$where")")
branch=$(git -C "$where" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
title="$host - $repo"
[ -n "$branch" ] && title="$title ($branch)"

snippet() { printf '%s' "$1" | tr '\n\r' '  ' | cut -c1-200; }

case "$kind" in
approval)
	prio=4
	tags=warning
	label="Approval needed"
	detail=$(snippet "$(field .message)")
	if [ "$event" = PermissionRequest ]; then
		cmd=$(field .tool_input.command)
		detail=$(field .tool_name)
		# the approvals that matter most: approving these IS the action
		case "$cmd" in
		*"gh pr merge"*) prio=5 tags=rotating_light label="MERGE approval" ;;
		*"rebuild.sh switch"* | *"nixos-rebuild switch"* | *"rebuild.sh test"*) prio=5 tags=rotating_light label="Activate-system approval" ;;
		*"gh pr create"*) label="Open-PR approval" ;;
		*"rebuild.sh push"* | *"git push"*) label="Push approval" ;;
		*"rebuild.sh dry"* | *"rebuild.sh revert"*) label="Rebuild approval" ;;
		*"sudo "*) label="sudo approval" ;;
		esac
		[ "$label" = "Approval needed" ] || detail=$(snippet "$cmd")
	fi
	;;
failed)
	prio=4
	tags=x
	label="Run failed"
	detail=$(snippet "$(field '.error_type // .error // .reason')")
	;;
info)
	prio=3
	tags=information_source
	label="Notice"
	detail=$(snippet "$(field .message)")
	;;
*)
	prio=3
	tags=white_check_mark
	label="Thread finished"
	detail=$(snippet "$(field .last_assistant_message)")
	;;
esac

[ -n "${AGENT_NOTIFY_LABEL:-}" ] && label="$AGENT_NOTIFY_LABEL"

if [ "$quiet" = 1 ]; then
	if [ "$kind" = finished ]; then
		log "event=$event session=$session kind=$kind action=quiet-dropped"
		exit 0
	fi
	# still delivered (so a blocked agent is not invisible) but not urgent
	prio=3
	[ "$kind" = info ] && prio=2
fi

body="$label"
[ -n "$detail" ] && body="$label: $detail"

# remote body: do not ship agent output off-machine unless asked to
remote_body="$label"
if [ "${force_text:-0}" = 1 ] || [ "$kind" != finished ] || [ -f "$cfg/include-text" ]; then
	remote_body="$body"
fi

sent=""

# desktop (GOD-KILLER). Hooks launched by systemd-run may lack the session
# bus variables, so fall back to the per-user socket.
if [ "$quiet" = 0 ] && [ "$kind" != info ] && command -v notify-send >/dev/null 2>&1; then
	if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "/run/user/$(id -u)/bus" ]; then
		DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
		export DBUS_SESSION_BUS_ADDRESS
	fi
	urgency=normal
	[ "$kind" = approval ] && urgency=critical
	if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] && notify-send -a "Agent" -u "$urgency" "$title" "$body" 2>/dev/null; then
		sent="desktop"
	fi
fi

# phone / anywhere: ntfy. Topic and token go through curl's stdin config so
# they never appear in `ps`.
if [ -r "$cfg/topic" ]; then
	topic=$(tr -d '[:space:]' <"$cfg/topic")
	server=https://ntfy.sh
	[ -r "$cfg/server" ] && server=$(tr -d '[:space:]' <"$cfg/server")
	esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
	{
		printf 'url = "%s/%s"\n' "$(esc "${server%/}")" "$(esc "$topic")"
		printf 'header = "Title: %s"\n' "$(esc "$title")"
		printf 'header = "Priority: %s"\n' "$prio"
		printf 'header = "Tags: %s"\n' "$tags"
		if [ -r "$cfg/token" ]; then
			printf 'header = "Authorization: Bearer %s"\n' "$(esc "$(tr -d '[:space:]' <"$cfg/token")")"
		fi
		printf 'data = "%s"\n' "$(esc "$remote_body")"
	} | curl -q -sS -K - --connect-timeout 5 --max-time 10 -o /dev/null 2>>"$state/curl.err" && sent="${sent:+$sent+}ntfy"
fi

log "event=$event type=$ntype session=$session kind=$kind quiet=$quiet action=sent:${sent:-none}"
exit 0
