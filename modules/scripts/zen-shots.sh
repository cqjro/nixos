# zen-shots [SITE] [OUTDIR]
#
# HUMAN-ONLY. Screenshots the same fixed page list as theme-shots, but in your REAL,
# logged-in Zen (Wayland/Hyprland): it focuses Zen, opens each URL in a new tab, waits,
# and `grim`s the active window into OUTDIR. Agents never run this (the managed policy
# denies it; it needs your compositor session) and nothing here is excluded from the
# sandbox. Run it from a terminal inside the worktree the agent works in, so the agent
# can read the images:
#
#   cd ~/.t3/worktrees/.nixos/<worktree>
#   zen-shots            # all sites into ./.log/zen-shots
#   zen-shots youtube    # one site
#
#   SITE    google | youtube | reddit | instagram | all (default all)
#   OUTDIR  default ./.log/zen-shots (gitignored; never commit these)
#   ZEN_SHOTS_WAIT=seconds to let each page settle (default 12)
#
# The images show whatever your account shows (recommendations, avatar, DMs badge): the
# agent that reads them sees it too. Look through them first and delete what you do not
# want to share. Do not touch the keyboard or mouse while it runs: it reads the focused
# window, and it refuses to take a shot unless that window is Zen.

URLS=@urls@
ZEN_BIN=zen-twilight
ZEN_CLASS=zen-twilight
WAIT=${ZEN_SHOTS_WAIT:-12}

die() {
	echo "zen-shots: $*" >&2
	exit 2
}

[[ $# -le 2 ]] || die "usage: zen-shots [google|youtube|reddit|instagram|all] [OUTDIR]"
site=${1:-all}
out=${2:-.log/zen-shots}
case $site in
google | youtube | reddit | instagram | all) ;;
*) die "unknown site '$site' (google|youtube|reddit|instagram|all)" ;;
esac
[[ $WAIT =~ ^[0-9]+$ ]] || die "ZEN_SHOTS_WAIT must be a whole number of seconds"

command -v "$ZEN_BIN" >/dev/null || die "$ZEN_BIN is not on PATH"
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || die "no Hyprland session in this shell (run it from a terminal on the desktop)"

mkdir -p -- "$out"
orig=$(hyprctl activewindow -j | jq -r '.address // empty')

active_class() {
	hyprctl activewindow -j | jq -r '.class // empty'
}

bad=0
while IFS='|' read -r -u 3 s page url; do
	[[ -z $s || $s == \#* ]] && continue
	[[ $site == all || $site == "$s" ]] || continue

	hyprctl dispatch focuswindow "class:$ZEN_CLASS" >/dev/null || true
	# an already-running Zen opens the URL in a new tab of its last window
	"$ZEN_BIN" "$url" >/dev/null 2>&1 &
	sleep "$WAIT"

	if [[ $(active_class) != "$ZEN_CLASS" ]]; then
		echo "zen-shots: $s/$page: the active window is not Zen, skipped (is Zen running on this session?)" >&2
		bad=1
		continue
	fi
	geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
	if grim -g "$geometry" "$out/$s-$page.png"; then
		echo "zen-shots: $s/$page -> $out/$s-$page.png"
	else
		echo "zen-shots: $s/$page: grim failed" >&2
		bad=1
	fi
done 3<"$URLS"

if [[ -n $orig ]]; then
	hyprctl dispatch focuswindow "address:$orig" >/dev/null || true
fi
echo "zen-shots: done. These are your logged-in pages: review $out before the agent reads it."
exit "$bad"
