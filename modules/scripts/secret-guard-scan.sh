#!/usr/bin/env bash
# secret-guard-scan: look for credentials in files you already have (agent
# transcripts, attachments, logs) using the same patterns as the hooks, and
# print ONLY "path: label: count". The matched text is never printed.
#
# Usage: secret-guard-scan.sh [--weak] PATH...
#   --weak   also run the noisy `weak` tier (expect many false positives in
#            transcripts that discuss passwords and tokens)
# Directories named "secrets" are skipped: never scan ~/.t3/userdata/secrets.
set -u
patterns="${SECRET_GUARD_PATTERNS:-$(dirname "${BASH_SOURCE[0]}")/secret-guard-patterns.txt}"
weak=0
if [ "${1:-}" = "--weak" ]; then weak=1; shift; fi
[ "$#" -gt 0 ] || { echo "usage: ${0##*/} [--weak] PATH..." >&2; exit 2; }

while IFS='|' read -r tier flags _modes label re; do
	case "$tier" in "" | \#*) continue ;; esac
	[ "$tier" = weak ] && [ "$weak" = 0 ] && continue
	opts=(-rIcE --exclude-dir=secrets --exclude-dir=.git --exclude-dir=node_modules)
	[ "$flags" = i ] && opts=(-rIcEi --exclude-dir=secrets --exclude-dir=.git --exclude-dir=node_modules)
	grep "${opts[@]}" -e "$re" -- "$@" 2>/dev/null |
		awk -F: -v l="$label" '{ n = $NF; if (n > 0) { sub(/:[0-9]+$/, ""); print $0 ": " l ": " n } }'
done <"$patterns"
