#!/usr/bin/env bash
# history-email-scrub: prepare the two files that remove personal email addresses
# from git history in the SAME `git filter-repo` run as the firmware rewrite
# (docs/firmware.md section 6; method in the private secrets audit).
#
# Usage: history-email-scrub.sh REPO_CLONE OUT_DIR
#   REPO_CLONE  the fresh clone you are about to rewrite (e.g. /tmp/nixos-rewrite)
#   OUT_DIR     where to write mailmap.txt and replace-text.txt. Must be OUTSIDE
#               any repo: the files contain the very addresses being removed.
#
# Every author/committer address that is not a noreply address is mapped to
# "cqjro <the GitHub noreply address found in the history>", and the same
# addresses (plus any *@cqjro.ca) are replaced inside file contents. Nothing is
# printed except counts. The commit "GitHub <noreply@github.com>" and Claude's
# noreply@anthropic.com trailer are left alone: they are not personal.
set -eu

repo="${1:?usage: ${0##*/} REPO_CLONE OUT_DIR}"
out="${2:?usage: ${0##*/} REPO_CLONE OUT_DIR}"
name="${NEW_NAME:-cqjro}"

case "$(cd "$out" 2>/dev/null && git rev-parse --show-toplevel 2>/dev/null || true)" in
	"") ;;
	*) echo "refusing: OUT_DIR is inside a git repo" >&2; exit 1 ;;
esac
mkdir -p "$out"

emails="$(git -C "$repo" log --all --format='%ae%n%ce' | sort -u)"
new="${NEW_EMAIL:-$(grep -m1 'users\.noreply\.github\.com$' <<<"$emails" || true)}"
[ -n "$new" ] || { echo "no users.noreply.github.com address in history; set NEW_EMAIL" >&2; exit 1; }
old="$(grep -vE 'noreply' <<<"$emails" | grep -v '^$' || true)"

: >"$out/mailmap.txt"
: >"$out/replace-text.txt"
while IFS= read -r e; do
	[ -n "$e" ] || continue
	printf '%s <%s> <%s>\n' "$name" "$new" "$e" >>"$out/mailmap.txt"
	printf 'literal:%s==>%s\n' "$e" "$new" >>"$out/replace-text.txt"
done <<<"$old"
# a commit made through the GitHub web UI carries the real name with the noreply address
git -C "$repo" log --all --format='%an%n%cn' | sort -u | grep -vxE "$name|GitHub" | while IFS= read -r n; do
	[ -n "$n" ] && printf '%s <%s> %s <%s>\n' "$name" "$new" "$n" "$new" >>"$out/mailmap.txt"
done
printf 'regex:[A-Za-z0-9._%%+-]+@cqjro\\.ca==>%s\n' "$new" >>"$out/replace-text.txt"

echo "addresses to replace: $(grep -c . <<<"$old")"
echo "mailmap lines:        $(wc -l <"$out/mailmap.txt")"
echo "replace-text lines:   $(wc -l <"$out/replace-text.txt")"
echo "written to $out (keep it out of git; delete after the rewrite)"
echo "add to filter-repo:   --mailmap $out/mailmap.txt --replace-text $out/replace-text.txt"
