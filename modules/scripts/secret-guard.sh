#!/usr/bin/env bash
# secret-guard: Claude Code hook that refuses prompts and tool calls carrying
# credentials, so a secret never reaches the model or the transcript.
#
# Usage (hook JSON arrives on stdin):
#   secret-guard.sh prompt   UserPromptSubmit: block the prompt
#   secret-guard.sh tool     PreToolUse: deny file writes, ask on anything else
#
# Patterns: $SECRET_GUARD_PATTERNS (default: secret-guard-patterns.txt next to
# this script). Never logs, echoes or writes the matched text; it reports only
# the label of the pattern that matched. Fails open on bad input (a broken hook
# must not lock the user out), so treat it as a safety net, not a boundary.
set -u

mode="${1:-}"
patterns="${SECRET_GUARD_PATTERNS:-$(dirname "${BASH_SOURCE[0]}")/secret-guard-patterns.txt}"
bypass="[allow-secret-pattern]"

input="$(cat)"
case "$mode" in
	prompt)
		text="$(jq -r '.prompt // empty' <<<"$input" 2>/dev/null)" || exit 0
		want=p
		;;
	tool)
		tool="$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null)"
		case "$tool" in
			# file-reading tools: only the path arguments are checked (a grep *pattern*
			# that merely mentions a name is not a read of that file)
			Read | Grep | Glob)
				text="$(jq -r '[.tool_input.file_path, .tool_input.path, .tool_input.glob, (if .tool_name == "Glob" then .tool_input.pattern else empty end)] | map(strings) | join("\n")' <<<"$input" 2>/dev/null)" || exit 0
				want=r
				;;
			*)
				text="$(jq -r '[.tool_input | .. | strings] | join("\n")' <<<"$input" 2>/dev/null)" || exit 0
				want=t
				;;
		esac
		;;
	*)
		exit 0
		;;
esac
[ -n "$text" ] || exit 0
[ -r "$patterns" ] || exit 0

skip_weak=0
if [ "$mode" = prompt ] && [[ "$text" == *"$bypass"* ]]; then
	skip_weak=1
fi

hit=""
while IFS='|' read -r tier flags modes label re; do
	case "$tier" in "" | \#*) continue ;; esac
	[[ "$modes" == *"$want"* ]] || continue
	[[ "$modes" == *b* ]] && [ "${tool:-}" != Bash ] && continue
	[ "$tier" = weak ] && [ "$skip_weak" = 1 ] && continue
	opts=-qE
	[ "$flags" = i ] && opts=-qiE
	if grep "$opts" -e "$re" <<<"$text"; then
		hit="$label"
		break
	fi
done <"$patterns"

[ -n "$hit" ] || exit 0

case "$mode" in
	prompt)
		reason="Secret guard: your message looks like it contains a ${hit}, so it was NOT sent to the agent. Do not paste secrets into a thread. Ask the agent to use the request_secret tool (a private card, the value never enters chat), or put the value in an on-host file yourself. If it was already real, treat it as exposed and rotate it (docs/secrets.md). For a false positive, add ${bypass} to the message (does not bypass high-confidence patterns)."
		jq -n --arg r "$reason" '{decision: "block", reason: $r, hookSpecificOutput: {hookEventName: "UserPromptSubmit", suppressOriginalPrompt: true}}'
		;;
	tool)
		case "$tool" in
			Write | Edit | MultiEdit | NotebookEdit) decision=deny ;;
			Read | Grep | Glob) decision=ask ;;
			*) decision=ask ;;
		esac
		reason="Secret guard: this ${tool:-tool} call matched: ${hit}. A credential must not be written into files, commands or the repo (keep it in an on-host file, see docs/secrets.md; or request_secret for a T3 tool); proprietary firmware must never enter git (docs/firmware.md)."
		jq -n --arg d "$decision" --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $d, permissionDecisionReason: $r}}'
		;;
esac
exit 0
