#!/usr/bin/env bash
# theme-shots-compare.sh SITE OUTDIR RAW_DIR OLD_DIR NEW_DIR
#
# Builds the RAW / OLD / NEW comparison set that every Zen site-styling thread hands to the
# human (docs/agents/theme-shots.md, "Review deliverable"). Each input is a saved theme-shots
# run (the PNGs you copied out of the run directory; the tool clears it on the next run):
#   RAW_DIR  a run containing <site>-<page>-<mode>-RAW_no-userContent.png     (no custom CSS)
#   OLD_DIR  a run containing <site>-<page>-<mode>-THEMED_with-userContent.png (master's CSS,
#            before your change; reuse saved OLD shots if master already has your work)
#   NEW_DIR  a run containing <site>-<page>-<mode>-THEMED_with-userContent.png (your candidate)
# RAW_DIR may be the same directory as NEW_DIR.
#
# Writes under OUTDIR (use <worktree>/.log/shots-keep/final, which is gitignored):
#   <page>/<page>_<viewport|full>_<RAW|OLD|NEW>.png
#   INDEX.md                 one row per page, absolute paths
#   VIEWPORT-COMPARISON.md   the viewport trio per page with the images embedded
# Plain bash and coreutils only; it reads only the three directories and writes only OUTDIR.
set -euo pipefail

if [[ $# -ne 5 ]]; then
	echo "usage: ${0##*/} SITE OUTDIR RAW_DIR OLD_DIR NEW_DIR" >&2
	exit 2
fi
site=$1
out=$2
raw_dir=$3
old_dir=$4
new_dir=$5

[[ $site =~ ^[a-z0-9]+$ ]] || { echo "SITE must be a plain lowercase word (got '$site')" >&2; exit 2; }
for d in "$raw_dir" "$old_dir" "$new_dir"; do
	[[ -d $d ]] || { echo "not a directory: $d" >&2; exit 2; }
done
mkdir -p -- "$out"
out=$(cd -- "$out" && pwd -P)
raw_dir=$(cd -- "$raw_dir" && pwd -P)
old_dir=$(cd -- "$old_dir" && pwd -P)
new_dir=$(cd -- "$new_dir" && pwd -P)

raw_state=RAW_no-userContent
themed_state=THEMED_with-userContent
re="^${site}-(.+)-(viewport|full)-(${raw_state}|${themed_state})\\.png\$"
re_rej="^${site}-(.+)-(viewport|full)-(${raw_state}|${themed_state})\\.REJECTED\\.png\$"

declare -A pages=() blocked=()
for d in "$raw_dir" "$old_dir" "$new_dir"; do
	for f in "$d"/"$site"-*.png; do
		[[ -e $f ]] || continue
		b=${f##*/}
		if [[ $b =~ $re ]]; then
			pages[${BASH_REMATCH[1]}]=1
		elif [[ $b =~ $re_rej ]]; then
			blocked[${BASH_REMATCH[1]}]=1
		fi
	done
done
[[ ${#pages[@]} -gt 0 ]] || { echo "no $site PNGs found in the three directories" >&2; exit 1; }

# copy_one PAGE MODE LABEL SRC_DIR STATE  -> prints the destination path, or nothing
copy_one() {
	local page=$1 mode=$2 label=$3 dir=$4 state=$5
	local src="$dir/$site-$page-$mode-$state.png"
	local dst="$out/$page/${page}_${mode}_${label}.png"
	[[ -f $src ]] || return 0
	mkdir -p -- "$out/$page"
	cp -f -- "$src" "$dst"
	printf '%s' "$dst"
}

declare -A path=()
mapfile -t sorted < <(printf '%s\n' "${!pages[@]}" | LC_ALL=C sort)
for p in "${sorted[@]}"; do
	for m in viewport full; do
		path["$p|$m|RAW"]=$(copy_one "$p" "$m" RAW "$raw_dir" "$raw_state")
		path["$p|$m|OLD"]=$(copy_one "$p" "$m" OLD "$old_dir" "$themed_state")
		path["$p|$m|NEW"]=$(copy_one "$p" "$m" NEW "$new_dir" "$themed_state")
	done
done

cell() { [[ -n ${path["$1|$2|$3"]:-} ]] && printf '`%s`' "${path["$1|$2|$3"]}" || printf 'n/a'; }
img() { [[ -n ${path["$1|$2|$3"]:-} ]] && printf '![](%s)' "${path["$1|$2|$3"]}" || printf '_missing_'; }

{
	echo "# $site: RAW / OLD / NEW comparison (index)"
	echo
	echo "- **RAW**: the site with NO custom CSS (theme-shots \`$raw_state\`)."
	echo "- **OLD**: the user's current theme on master BEFORE this change (\`$themed_state\`)."
	echo "- **NEW**: the candidate in the worktree (\`$themed_state\`)."
	echo "- Logged-out pages only. A full-page shot taller than 7000 px is cut (see the manifest note)."
	echo
	echo "| page | RAW viewport | OLD viewport | NEW viewport | RAW full | OLD full | NEW full |"
	echo "| --- | --- | --- | --- | --- | --- | --- |"
	for p in "${sorted[@]}"; do
		echo "| $p | $(cell "$p" viewport RAW) | $(cell "$p" viewport OLD) | $(cell "$p" viewport NEW) | $(cell "$p" full RAW) | $(cell "$p" full OLD) | $(cell "$p" full NEW) |"
	done
	for p in "${!blocked[@]}"; do
		[[ -n ${pages[$p]:-} ]] || echo "| $p | BLOCKED (REJECTED block page, skipped) | | | | | |"
	done
} >"$out/INDEX.md"

{
	echo "# $site: viewport comparison (RAW / OLD / NEW)"
	echo
	echo "RAW = site with no custom CSS. OLD = the user's current theme on master before the change. NEW = the candidate."
	echo
	for p in "${sorted[@]}"; do
		echo "**$p**"
		echo
		echo "| RAW | OLD | NEW |"
		echo "| --- | --- | --- |"
		echo "| $(img "$p" viewport RAW) | $(img "$p" viewport OLD) | $(img "$p" viewport NEW) |"
		echo
	done
	echo "Ads, thumbnails and recommendations differ between captures; compare the layout and colours, not the content."
	echo
	echo "Full-page shots (a page taller than 7000 px is cut) are listed in \`$out/INDEX.md\` and sit in \`$out/<page>/<page>_full_<RAW|OLD|NEW>.png\`."
} >"$out/VIEWPORT-COMPARISON.md"

echo "wrote $out/INDEX.md and $out/VIEWPORT-COMPARISON.md for ${#sorted[@]} pages"
