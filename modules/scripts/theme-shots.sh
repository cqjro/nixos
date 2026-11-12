# theme-shots SITE WORKTREE [OUTDIR]
#
# Screenshots of google, youtube, reddit, instagram and wikipedia in a throwaway
# headless profile of the installed Zen (zen-twilight), RAW (no CSS) and THEMED (with the
# userContent.css this flake generates), each as a viewport shot and a full-page shot, so an
# agent can see which per-site rules (modules/theme/webstyling/*.nix) are broken. Files:
# <site>-<page>-<mode>-<state>.png (mode viewport|full, state RAW_no-userContent|
# THEMED_with-userContent) and a manifest.tsv listing every one. LOGGED OUT ONLY: every shot gets a brand
# new profile and an empty HOME that are deleted on exit; no cookie, login or real
# profile is ever read or kept. Packaged by modules/theme/theme-shots.nix and run as
# /run/current-system/sw/bin/theme-shots. Design, limits and trust assumptions:
# docs/agents/theme-shots.md and docs/agents/security.md ("theme-shots runs
# unsandboxed").
#
#   SITE     google | youtube | reddit | instagram | wikipedia | all
#   WORKTREE absolute path of a worktree under ~/.t3/worktrees/<project>/<name>
#   OUTDIR   .log/theme-shots or below (default .log/theme-shots; relative paths are
#            relative to the worktree). The worktree's .gitignore must ignore .log/
#
# SECURITY INVARIANT: this runs OUTSIDE the agent sandbox (sandbox.excludedCommands),
# as the owner, with the owner's network, and an agent chooses its three arguments.
# So nothing the caller supplies may choose a URL, a command, a browser flag, a
# profile or HOME path, or a path the script trusts. There is NO profile argument and
# there will not be one: a persistent profile (e.g. a logged-in test account) is out
# of scope, and the profile directory is an internal detail of make_profile():
#   - the URLs come from a fixed list in the Nix store (theme-shots-urls.txt);
#   - SITE is one of six words; WORKTREE must resolve to exactly
#     ~/.t3/worktrees/<project>/<name>, owned by the user, and the CALLER'S cwd must be
#     inside it (an agent's cwd is its own worktree, never another thread's); OUTDIR
#     must resolve (after symlinks) to <WORKTREE>/.log/theme-shots or below, the
#     worktree's .gitignore must list .log/ (checked by reading the file: no git runs
#     in the agent's directory), and the script chdirs
#     into it with cd -P and re-checks the kernel's view of the cwd, so every write
#     uses a fixed file name in a directory it holds open (a swap between the checks
#     can still make mkdir create empty directories elsewhere, never write files);
#   - every child process gets a rebuilt environment (fixed PATH, passwd home, no
#     GIT_*/NIX_*/LD_*/PYTHON*/proxy/MOZ_* from the caller); Zen gets its own empty
#     HOME, a fresh profile (both under a private mktemp dir, asserted not to be the
#     real $HOME, ~/.mozilla, ~/.zen or ~/.config/zen) and a PAC file that sends everything except the
#     sites' own hosts to a dead proxy (so generated CSS cannot reach
#     localhost, the LAN or other hosts over http(s); not file:, and the allowed
#     suffixes include hostable ones such as googleapis.com);
#   - the nix evaluation is pure (no --impure, --no-accept-flake-config). That is NOT
#     a read confinement: a flake can declare path:/git+file: inputs, IFD or hashed
#     fetches and read them as the owner, exactly as the already-excluded
#     `nix eval *` can. Do not rely on it as a boundary;
#   - the prefs come from the flake's real Zen settings, but only through an
#     allowlist (PREF_RE, plain values) and BEFORE the script's own fixed block, so a
#     flake cannot change the proxy, sandbox, telemetry or any non-rendering pref;
#   - the browser is driven over WebDriver (geckodriver) so the shot can wait for the
#     page. That opens TWO unauthenticated loopback ports for the seconds one shot
#     lives (geckodriver's, and the Marionette port it picks): geckodriver listens on
#     127.0.0.1 only, starts exactly one browser, and is killed after every shot (and by
#     the EXIT trap); page code cannot reach either port because the PAC sends
#     127.0.0.1/localhost to the dead proxy. Every WebDriver request is built here from
#     constants and the fixed URL list: no caller text is ever sent to the browser. The
#     full-page capture runs three FIXED page scripts (the JS_* constants: scroll, scroll to
#     the top, read the document height) through execute/sync, with no argument; what the
#     page answers is only accepted as two integers (wd_exec) and clamped (CAP_PX) before it
#     is used in a window/rect request, and the page cannot make the capture loop (SCROLL_STEPS).
# Changing the argument parsing, the PAC list, the WebDriver flow or the child
# environment is a tier-2 review item.

URLS=@urls@
ATTR='nixosConfigurations.GOD-KILLER.config.home-manager.users.cairo.programs.zen-browser.profiles.default'
ZEN=zen-twilight
# the installed Zen behind a stub that answers --version like Firefox (geckodriver refuses a
# binary whose --version is "Mozilla Zen ..."); built in modules/theme/theme-shots.nix
zen_bin=@zen_driver@
# flake prefs taken over into the throwaway profile (rendering only: colour scheme,
# fonts, Zen view, the userChrome/userContent switch). Anything else is dropped and listed.
PREF_RE='\A(ui\.|layout\.|font\.|reader\.|zen\.view\.|toolkit\.legacyUserProfileCustomizations\.stylesheets\z)'
UA='Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0'
# Firefox's PNG encoder is weak (a blank 1400x1000 page is still ~27 KB), but gzip sees
# through it: blank 583 bytes, a flat page with two text lines 5.5 KB, a busy page 185 KB
# (measured 2026-11-08). Below this a shot is a blank page. It cannot tell a rendered
# block page or consent wall from a real one: the agent still has to look at the image.
MIN_GZ_BYTES=3000
# seconds to wait after the load event before the screenshot, so script-rendered pages
# (all the sites) have painted. Zen's own --screenshot had no such wait: it shot at the
# first committed navigation and came out blank, a skeleton or not at all.
SETTLE_SECS=6
# full-page capture, taken in the same browser session after the viewport shot: scroll in at
# most SCROLL_STEPS steps of one viewport height (SCROLL_WAIT s after each) so lazy-loaded
# content appears (an infinite-scroll page just stops at the last step, it cannot loop), go
# back to the top and wait FULL_SETTLE_SECS. Two methods, tried in this order: (1) a page that
# fits under CAP_PX is shot with geckodriver's moz/screenshot/full (the whole document, the
# layout stays at viewport size: 100vh sections and sticky bars are not distorted); that
# endpoint cannot be clamped (Gecko's own limit is 32767 px), so (2) a taller page, or a
# failure of (1), makes the window as tall as the document, at most CAP_PX, and takes the
# ordinary screenshot (clamped, but 100vh sections stretch to the tall window). CAP_PX is the
# most a PNG is ever tall; a page taller than that is cut and the report says so.
CAP_PX=7000
SCROLL_STEPS=6
SCROLL_WAIT=0.7
FULL_SETTLE_SECS=3
# The only page scripts this tool ever runs (WebDriver "execute/sync"): fixed text, no
# argument, no caller or URL-list data in them. They return the document height and the
# bottom edge of the view; the script parses nothing else of the answer (wd_exec).
JS_STEP='window.scrollBy(0, window.innerHeight); var d = document.documentElement; return [Math.floor(d.scrollHeight), Math.floor(window.scrollY + window.innerHeight)];'
JS_TOP='window.scrollTo(0, 0); var d = document.documentElement; return [Math.floor(d.scrollHeight), Math.floor(window.innerHeight)];'
JS_PROBE='var d = document.documentElement; return [Math.floor(d.scrollHeight), Math.floor(window.scrollY + window.innerHeight)];'
# suffixes the browser may reach (the sites and their asset CDNs); everything else is blackholed.
# wikipedia.org carries every language/wiki and its load.php assets, wikimedia.org the
# images (upload.wikimedia.org) and the login/analytics hosts; both are suffixes, so
# neither is narrowed to the hosts a page was seen to use (unverified live, see the docs)
ALLOWED_DOMAINS=(
	google.com gstatic.com googleapis.com googleusercontent.com
	youtube.com ytimg.com ggpht.com googlevideo.com
	reddit.com redditstatic.com redditmedia.com redd.it
	instagram.com cdninstagram.com fbcdn.net facebook.com facebook.net
	wikipedia.org wikimedia.org
)

die() {
	echo "theme-shots: $*" >&2
	exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || die "usage: theme-shots google|youtube|reddit|instagram|wikipedia|all WORKTREE [OUTDIR]"
site=$1
wt_arg=$2
out_arg=${3:-.log/theme-shots}

case $site in
google | youtube | reddit | instagram | wikipedia | all) ;;
*) die "unknown site '$site' (google|youtube|reddit|instagram|wikipedia|all)" ;;
esac

safe_re='^[A-Za-z0-9._/+@-]+$'
[[ $wt_arg =~ $safe_re ]] || die "worktree path has characters outside [A-Za-z0-9._/+@-]"
[[ $out_arg =~ $safe_re ]] || die "output dir has characters outside [A-Za-z0-9._/+@-]"
[[ $wt_arg == /* ]] || die "worktree must be an absolute path"

uid=$(id -u)
user=$(id -un)
home=$(getent passwd "$uid" | cut -d: -f6)
[[ $home == /?* ]] || die "cannot determine the passwd home"

# the caller's real directory (kernel view, not a $PWD string)
caller=$(readlink -f /proc/self/cwd)

wt=$(realpath -e -- "$wt_arg") || die "no such worktree: $wt_arg"
# re-check the RESOLVED path: a symlink may point at a directory whose real name has
# characters that would change the flake reference below (?, #, &)
[[ $wt =~ $safe_re ]] || die "resolved worktree path has characters outside [A-Za-z0-9._/+@-]"
[[ $wt == "$home"/.t3/worktrees/?*/?* && ${wt#"$home"/.t3/worktrees/} != */*/* ]] ||
	die "worktree must be exactly $home/.t3/worktrees/<project>/<name>"
[[ -f $wt/flake.nix && -e $wt/.git ]] || die "$wt is not a flake worktree (flake.nix and .git needed)"
[[ $(stat -c %u -- "$wt") == "$uid" ]] || die "$wt is not owned by $user"
# only the worktree you are working in: another thread's worktree is not yours to evaluate or write to
[[ $caller == "$wt" || $caller == "$wt"/* ]] || die "run it from inside the worktree (cwd is $caller)"

if [[ $out_arg == /* ]]; then out=$out_arg; else out=$wt/$out_arg; fi
out=$(realpath -m -- "$out")
[[ $out =~ $safe_re ]] || die "resolved output dir has characters outside [A-Za-z0-9._/+@-]"
[[ $out == "$wt"/.log/theme-shots || $out == "$wt"/.log/theme-shots/?* ]] ||
	die "output dir must be $wt/.log/theme-shots or below"
# screenshots must never be committable: refuse unless the worktree ignores .log/
# (read from the file: no git runs in a directory the agent controls)
if [[ ! -f $wt/.gitignore ]] || ! grep -Eqx '/?\.log/?' "$wt/.gitignore" || grep -Eq '^!.*\.log' "$wt/.gitignore"; then
	die "$wt/.gitignore must ignore .log/ (a line '.log/'), and not re-include it"
fi

# create and enter the directory from the worktree root, checking the KERNEL's view of
# the directory we hold (readlink on /proc/self/cwd, not a path string that could be
# re-resolved after a symlink swap)
cd -P -- "$wt"
[[ $(readlink -f /proc/self/cwd) == "$wt" ]] || die "worktree changed under us"
[[ ! -L .log ]] || die ".log is a symlink"
mkdir -p -- "${out#"$wt"/}"
cd -P -- "${out#"$wt"/}"
[[ $(readlink -f /proc/self/cwd) == "$out" ]] || die "output dir left $wt/.log/ (symlink swapped?)"

# everything the browser touches lives under one private mktemp dir, deleted on exit
work=$(mktemp -d /tmp/theme-shots.XXXXXX)
gd_pid=""
cleanup() {
	if [[ -n $gd_pid ]]; then
		kill -TERM "$gd_pid" 2>/dev/null || true
		wait "$gd_pid" 2>/dev/null || true
		kill -KILL -- "-$gd_pid" 2>/dev/null || true
	fi
	if [[ -n ${work:-} ]]; then rm -rf -- "$work"; fi
}
trap cleanup EXIT

# hard refusal: a profile or HOME for the browser may never be the real one. Checked on
# the resolved path, for the private dir and again for every per-shot dir.
assert_private_dir() {
	local p
	p=$(realpath -e -- "$1") || die "profile dir $1 vanished"
	[[ $p == "$work" || $p == "$work"/* ]] || die "refusing profile/HOME outside the private temp dir: $p"
	case $p in
	"$home" | "$home"/* | "$home"/.mozilla | "$home"/.zen | "$home"/.config/zen | /root | /root/*)
		die "refusing a profile/HOME under the real home, ~/.mozilla, ~/.zen or ~/.config/zen: $p"
		;;
	esac
}
assert_private_dir "$work"

# rebuilt environment for every child; the caller's is never passed on
clean() {
	env -i "PATH=$PATH" "HOME=$home" "USER=$user" "LOGNAME=$user" "LANG=C.UTF-8" \
		"SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" "$@"
}

echo "theme-shots: evaluating the Zen profile (userContent + settings) from $wt (GOD-KILLER)"
if ! clean timeout 900 nix eval --json --no-write-lock-file --no-accept-flake-config \
	--apply 'p: { css = p.userContent; settings = p.settings; }' "git+file://$wt#$ATTR" \
	>"$work/eval.json" 2>"$work/nix.err" </dev/null; then
	echo "theme-shots: nix eval failed:" >&2
	tail -n 20 "$work/nix.err" >&2
	echo "theme-shots: files that are not git-added are invisible to the flake (git add the new ones)" >&2
	exit 3
fi
jq -r '.css' "$work/eval.json" >"$work/userContent.css" || die "evaluation result is not the expected JSON"
grep -q '@-moz-document' "$work/userContent.css" || die "evaluated userContent has no @-moz-document rule; refusing to continue"

# prefs = the flake's real Zen settings, rendering prefs only (see PREF_RE); plain values
jq -r --arg re "$PREF_RE" '
	.settings | to_entries[]
	| select((.key | test($re)) and (.key | test("\\A[A-Za-z0-9._-]+\\z"))
		and ((.value | type) == "boolean" or (.value | type) == "number"
			or ((.value | type) == "string" and (.value | length) < 200 and (.value | test("[\\n\\r]") | not))))
	| "user_pref(\(.key | @json), \(.value | @json));"' "$work/eval.json" >"$work/prefs.js" ||
	die "cannot read the flake's Zen settings"
jq -r --arg re "$PREF_RE" '
	.settings | to_entries[]
	| select(((.key | test($re)) and (.key | test("\\A[A-Za-z0-9._-]+\\z"))
		and ((.value | type) == "boolean" or (.value | type) == "number"
			or ((.value | type) == "string" and (.value | length) < 200 and (.value | test("[\\n\\r]") | not)))) | not)
	| .key' "$work/eval.json" >"$work/dropped-prefs.txt"
# the whole tool rests on this one: real Zen would not apply userContent.css without it either
jq -e '.settings["toolkit.legacyUserProfileCustomizations.stylesheets"] == true' "$work/eval.json" >/dev/null ||
	{
		echo "theme-shots: the flake's Zen settings do not set toolkit.legacyUserProfileCustomizations.stylesheets = true:" >&2
		echo "theme-shots: real Zen would not apply userContent.css either, so no meaningful shot exists" >&2
		exit 3
	}

# PAC: only the sites' own hosts go direct, everything else (localhost, the LAN,
# any host a CSS url() names) hits a dead proxy. Tested 2026-11-08 in the sandbox
# against a local server: without allow_hijacking_localhost Firefox never proxies
# localhost (the PAC is ignored for it), with it a blackholed 127.0.0.1 gets no
# connection (the shot times out) and a PAC that allows 127.0.0.1 loads the page.
{
	echo 'function FindProxyForURL(url, host) {'
	printf '\tvar ok = ['
	for d in "${ALLOWED_DOMAINS[@]}"; do printf '"%s",' "$d"; done
	echo '];'
	echo '	for (var i = 0; i < ok.length; i++) {'
	echo '		if (host === ok[i] || dnsDomainIs(host, "." + ok[i])) return "DIRECT";'
	echo '	}'
	echo '	return "PROXY 127.0.0.1:9";'
	echo '}'
} >"$work/proxy.pac"

# one fresh profile + HOME per shot, inside the private temp dir and deleted with it;
# $1 = profile dir, $2 = with CSS (1) or not (0). This directory is an internal detail:
# no argument, option or variable can name a profile.
make_profile() {
	local prof=$1 css=$2
	mkdir -p -- "$prof/chrome"
	assert_private_dir "$prof"
	# the flake's rendering prefs first, the script's fixed block LAST (last user_pref wins)
	cp -- "$work/prefs.js" "$prof/user.js"
	cat >>"$prof/user.js" <<EOF
user_pref("network.proxy.type", 2);
user_pref("network.proxy.autoconfig_url", "file://$work/proxy.pac");
user_pref("network.proxy.failover_direct", false);
user_pref("network.proxy.no_proxies_on", "");
user_pref("network.proxy.allow_hijacking_localhost", true);
user_pref("network.trr.mode", 5);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.aboutwelcome.enabled", false);
user_pref("browser.startup.homepage_override.mstone", "ignore");
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("app.update.auto", false);
user_pref("app.update.enabled", false);
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
EOF
	if [[ $css == 1 ]]; then cp -- "$work/userContent.css" "$prof/chrome/userContent.css"; fi
}

# WebDriver plumbing. One shot = one geckodriver on 127.0.0.1 (random port, alive only for
# this shot) that starts one Zen on the fresh profile; the shot loads the URL, waits for
# the load event, waits SETTLE_SECS more, takes the viewport screenshot, then (full_capture)
# scrolls, resizes the window and takes the full-page screenshot, and quits. Every request
# body is built from constants and the fixed URL list; the page scripts are the JS_* constants.
wd_port="" wd_out="" wd_sid="" wd_t=30
wd() { # $1 = method, $2 = path, $3 = optional JSON body; response body -> $wd_out; fails on non-2xx
	local code body=()
	if [[ -n ${3:-} ]]; then body=(-d "$3"); fi
	: >"$wd_out"
	code=$(clean curl -q -sS --noproxy '*' --max-time "$wd_t" -X "$1" -H 'Content-Type: application/json' \
		"${body[@]}" -o "$wd_out" -w '%{http_code}' "http://127.0.0.1:$wd_port$2" 2>/dev/null </dev/null) || return 1
	[[ $code == 2?? ]]
}
# the WebDriver error of the last failed request, bounded and printable (untrusted text)
wd_msg() {
	{ jq -r '"\(.value.error // "no response"): \((.value.message // "")[:160])"' "$wd_out" 2>/dev/null || echo "no response"; } |
		head -n 1 | tr -c '[:print:]' '?'
}
stop_driver() {
	if [[ -n $gd_pid ]]; then
		kill -TERM "$gd_pid" 2>/dev/null || true # timeout forwards it to the whole group (geckodriver, Zen)
		wait "$gd_pid" 2>/dev/null || true
		kill -KILL -- "-$gd_pid" 2>/dev/null || true # timeout exits with geckodriver: finish any Zen it left
		gd_pid=""
	fi
}


# wd_exec runs one of the FIXED page scripts above (never anything built from the URL list or
# the caller) in the page and parses what it returns: the document height and the bottom edge
# of the view, as integers of at most 8 digits. The page is untrusted and can return anything
# (or override Math.floor): a result that is not exactly two such integers is a failure, and
# nothing else of it is kept. Sets js_h and js_y.
js_h="" js_y=""
wd_exec() { # $1 = one of JS_STEP, JS_TOP, JS_PROBE
	local body out re='^([0-9]{1,8}) ([0-9]{1,8})$'
	js_h="" js_y=""
	body=$(jq -n --arg s "$1" '{script: $s, args: []}')
	wd POST "/session/$wd_sid/execute/sync" "$body" || return 1
	out=$(jq -r '.value | if type == "array" and length == 2 and (.[0] | type) == "number" and (.[1] | type) == "number" then "\(.[0] | floor) \(.[1] | floor)" else empty end' "$wd_out" 2>/dev/null) || out=""
	if [[ ! $out =~ $re ]]; then
		printf '%s' '{"value":{"error":"unexpected script result","message":""}}' >"$wd_out"
		return 1
	fi
	js_h=${BASH_REMATCH[1]} js_y=${BASH_REMATCH[2]}
}

# the width and height (pixels) of a PNG, from its IHDR chunk; "0 0" if it is not readable
png_dims() { # $1 = file
	local b=()
	read -r -a b < <(od -An -tu1 -j16 -N8 -- "$1" 2>/dev/null) || true
	if [[ ${#b[@]} -eq 8 ]]; then
		echo "$(((b[0] << 24) + (b[1] << 16) + (b[2] << 8) + b[3])) $(((b[4] << 24) + (b[5] << 16) + (b[6] << 8) + b[7]))"
	else
		echo "0 0"
	fi
}

# full_capture() is the second shot of a session: the viewport shot is already taken. It
# scrolls (at most SCROLL_STEPS steps, then back to the top), makes the window as tall as the
# document (at most CAP_PX), settles and takes the ordinary screenshot of the now tall
# viewport. On failure it sets $full_err; the viewport shot is not affected.
full_h=0 full_cut=0 full_err="" full_method=""
full_capture() { # $1 = png path (the session is open on the loaded page)
	local i prev=0 target h
	full_h=0 full_cut=0 full_err="" full_method=""
	wd_t=20
	for ((i = 0; i < SCROLL_STEPS; i++)); do
		wd_exec "$JS_STEP" || { full_err="scroll: $(wd_msg)"; return 1; }
		sleep "$SCROLL_WAIT"
		# at the bottom and nothing new since the previous step: nothing is left to load
		if ((10#$js_y >= 10#$js_h && 10#$js_h <= prev)); then break; fi
		prev=$((10#$js_h))
	done
	wd_exec "$JS_TOP" || { full_err="scroll back to the top: $(wd_msg)"; return 1; }
	sleep 1
	wd_exec "$JS_PROBE" || { full_err="measure: $(wd_msg)"; return 1; }
	full_h=$((10#$js_h))
	if ((full_h <= CAP_PX)); then
		# method 1, geckodriver's whole-document shot: the layout stays at viewport size (a
		# 100vh section stays 1000 px, sticky and fixed bars stay where they are), but its
		# height cannot be clamped, so it is only used for a page that fits under CAP_PX
		sleep "$FULL_SETTLE_SECS"
		wd_t=60
		if wd GET "/session/$wd_sid/moz/screenshot/full" &&
			jq -r '.value // empty' "$wd_out" | base64 -d >"$1" 2>/dev/null &&
			[[ $(head -c 4 -- "$1" | tail -c 3) == PNG ]]; then
			read -r _ h < <(png_dims "$1")
			if ((h <= CAP_PX)); then
				full_method="document shot"
				return 0
			fi # the document grew past the cap while it was shot: take the clamped shot below
		fi
		rm -f -- "$1"
		wd_t=20
	fi
	# method 2, a window as tall as the document (at most CAP_PX): always clamped, but
	# viewport-relative layout (100vh) is stretched to the tall window
	target=$full_h
	((target >= 1000)) || target=1000
	if ((target > CAP_PX)); then
		target=$CAP_PX
		full_cut=1
	fi
	# the window's outer size is the viewport plus Zen's 194 x 16 px of sidebar and frame
	wd POST "/session/$wd_sid/window/rect" "{\"width\":1594,\"height\":$((target + 16))}" || { full_err="resize: $(wd_msg)"; return 1; }
	sleep "$FULL_SETTLE_SECS"
	wd_t=60
	wd GET "/session/$wd_sid/screenshot" || { full_err="screenshot: $(wd_msg)"; return 1; }
	jq -r '.value // empty' "$wd_out" | base64 -d >"$1" 2>/dev/null || { full_err="screenshot was not base64"; return 1; }
	[[ $(head -c 4 -- "$1" | tail -c 3) == PNG ]] || { full_err="screenshot is not a PNG"; return 1; }
	full_method="tall window"
}

# drive() runs the whole WebDriver conversation for one shot; on failure it sets $shot_err.
# The viewport shot comes first (loaded, settled, as always); then, unless the browser ended
# on a block URL, the full-page shot (best effort: its failure only sets $full_err)
drive() { # $1 = url, $2 = iso dir, $3 = viewport png path, $4 = full-page png path
	local caps
	wd_port="" wd_sid=""
	for _ in $(seq 1 200); do
		kill -0 "$gd_pid" 2>/dev/null || { shot_err="geckodriver exited at startup"; return 1; }
		wd_port=$(grep -oE 'Listening on 127\.0\.0\.1:[0-9]+' "$2/gd.log" | head -n 1 | grep -oE '[0-9]+$') || wd_port=""
		[[ -n $wd_port ]] && break
		sleep 0.05
	done
	[[ -n $wd_port ]] || { shot_err="geckodriver did not report its port"; return 1; }
	caps=$(jq -n --arg bin "$zen_bin" --arg prof "$2/profile" '{capabilities: {alwaysMatch: {
		browserName: "firefox", pageLoadStrategy: "normal",
		timeouts: {pageLoad: 60000, script: 10000, implicit: 0},
		"moz:firefoxOptions": {binary: $bin, args: ["--headless", "-profile", $prof]}}}}')
	wd_t=60
	wd POST /session "$caps" || { shot_err="new session: $(wd_msg)"; return 1; }
	wd_sid=$(jq -r '.value.sessionId // empty' "$wd_out")
	[[ $wd_sid =~ ^[A-Za-z0-9-]+$ ]] || { shot_err="no usable session id"; wd_sid=""; return 1; }
	wd_t=30
	# outer window size: Zen's sidebar and frame take 194 x 16 px, leaving a 1400 x 1000
	# viewport (measured 2026-11-09 with Zen 1.24t); best effort, the shot still works without
	wd POST "/session/$wd_sid/window/rect" '{"width":1594,"height":1016}' || true
	wd_t=90
	wd POST "/session/$wd_sid/url" "$(jq -n --arg u "$1" '{url: $u}')" || { shot_err="load: $(wd_msg)"; return 1; }
	sleep "$SETTLE_SECS"
	wd_t=30
	# where the browser ended up (after redirects and script navigation), for the
	# interstitial check; best effort, text is the page's own, so bounded and printable
	if wd GET "/session/$wd_sid/url"; then
		shot_url=$(jq -r '.value // empty' "$wd_out" 2>/dev/null | head -n 1 | head -c 2048 | tr -c '[:print:]' '?') || true # a SIGPIPE from head -c on a long URL still leaves the truncated text
	fi
	wd_t=60
	wd GET "/session/$wd_sid/screenshot" || { shot_err="screenshot: $(wd_msg)"; return 1; }
	jq -r '.value // empty' "$wd_out" | base64 -d >"$3" 2>/dev/null || { shot_err="screenshot was not base64"; return 1; }
	[[ $(head -c 4 -- "$3" | tail -c 3) == PNG ]] || { shot_err="screenshot is not a PNG"; return 1; }
	if [[ $shot_url =~ $interstitial_re ]]; then
		full_err="skipped: the browser ended on a block URL, so no full-page shot was taken"
		return 0
	fi
	full_capture "$4" || true
}

# shoot() leaves its diagnostics in these (the profile and its logs are deleted with
# $work, so the failure report needs them copied out): the failure reason, how long it
# took, a copy of geckodriver's output, which includes Zen's ($work/last-zen.log), and
# the number of crash dumps Zen left.
shot_err="" shot_secs=0 shot_dumps=0 shot_url=""
shoot() { # $1 = url, $2 = css (0|1), $3 = viewport png path, $4 = full-page png path
	local iso rc=0 t0=$SECONDS
	shot_err="" shot_url="" full_err="" full_h=0 full_cut=0 full_method=""
	rm -f -- "$work/last-zen.log" # never show the previous shot's output for this one
	iso=$(mktemp -d "$work/iso.XXXXXX")
	mkdir -p -- "$iso/tmp"
	assert_private_dir "$iso"
	make_profile "$iso/profile" "$2"
	wd_out=$iso/wd.json
	# geckodriver (and the Zen it starts) get the rebuilt environment; timeout makes them
	# one process group, so the TERM in stop_driver, or the 240 s limit, ends both
	env -i "PATH=$PATH" "HOME=$iso" "USER=$user" "LANG=C.UTF-8" "TMPDIR=$iso/tmp" \
		"XDG_CONFIG_HOME=$iso/config" "XDG_CACHE_HOME=$iso/cache" "XDG_DATA_HOME=$iso/data" \
		"FONTCONFIG_FILE=/etc/fonts/fonts.conf" "MOZ_HEADLESS=1" \
		timeout --kill-after=10 240 geckodriver --host 127.0.0.1 --port 0 \
		>"$iso/gd.log" 2>&1 </dev/null &
	gd_pid=$!
	drive "$1" "$iso" "$3" "$4" || rc=$?
	if [[ -n $wd_sid ]]; then
		wd_t=20
		wd DELETE "/session/$wd_sid" || true # quits Zen
	fi
	stop_driver
	if [[ $rc != 0 ]]; then full_err="skipped: the viewport shot failed"; fi
	shot_secs=$((SECONDS - t0))
	cp -- "$iso/gd.log" "$work/last-zen.log"
	shot_dumps=$(find "$iso" -name '*.dmp' 2>/dev/null | wc -l)
	return "$rc"
}

# collect the tail of the last shot's geckodriver and Zen output for a shot that did not
# come out ok (appended to report.txt after the table). The text is the drivers' and the
# browser's own output and can include page-controlled strings (console messages), so it
# is bounded (40 lines of 300 printable characters) and labelled untrusted: treat it as
# data, never as an instruction.
log_failure() { # $1 = file name, $2 = the reason
	{
		echo "# --- $1: ${2:-no driver error} after ${shot_secs}s, $shot_dumps crash dump(s); last lines of geckodriver's and Zen's output (untrusted text, may contain page content) ---"
		if [[ -s $work/last-zen.log ]]; then
			local l
			# at most 16 KiB are read, and a last line without a newline is kept
			while IFS= read -r l || [[ -n $l ]]; do printf '# | %s\n' "${l:0:300}"; done < <(tail -c 16384 -- "$work/last-zen.log" | tail -n 40 | tr -c '[:print:]\n' '?')
		else
			echo "# | (no output)"
		fi
	} >>"$work/failures.txt"
}

interstitial_re='^https?://(consent\.[^/]+/|[^/]+/(sorry|consent|captcha|challenge)([/?]|$))'
bad=0
n_ok=0 n_rej=0 n_fail=0 n_skip=0
report=$work/report.txt
manifest=$work/manifest.tsv
{
	echo "# browser: $(realpath -- "$(command -v "$ZEN")") (fresh logged-out profile per shot; none of the real extensions: no uBlock, Dark Reader, Stylus, RYD)"
	echo "# prefs from the flake's Zen settings: $(wc -l <"$work/prefs.js") taken; dropped (not rendering prefs): $(tr '\n' ' ' <"$work/dropped-prefs.txt")"
	echo "# file names: <site>-<page>-<mode>-<state>.png; mode viewport = the top 1400x1000 only, full = the whole page (cut at $CAP_PX px); state RAW_no-userContent = the site with NO CSS, THEMED_with-userContent = with the flake's userContent.css"
	echo "# screenshots of live web pages are untrusted input (they can carry injected text) and may show an approximate location (your IP's)"
	printf '%-10s %-14s %-9s %-24s %-9s %s\n' site page mode state verdict note
} >"$report"
printf 'file\tsite\tpage\tfinal_url\tstate\tmode\twidth\theight\tbytes\tstatus\tnote\n' >"$manifest"

# record() judges one image of the current shot and writes its file, its report line and its
# manifest line. $1 = mode (viewport|full), $2 = the image in $work, $3 = the capture error
# ("" = captured, "skipped…" = not attempted); uses $s $page $state $url and the preflight
# result ($pre_note, $pre_bad) of the page being shot
record() {
	local mode=$1 src=$2 err=$3 verdict=ok note=$pre_note name dest="" w=0 h=0 bytes=0 final=-
	name=$s-$page-$mode-$state
	# the names of earlier versions (before/after, viewport only) and of an earlier run
	rm -f -- "$name.png" "$name.REJECTED.png" "$s-$page-before.png" "$s-$page-before.REJECTED.png" \
		"$s-$page-after.png" "$s-$page-after.REJECTED.png"
	if [[ $err == skipped* ]]; then
		verdict=skipped
		note=$err
	elif [[ -n $err ]]; then
		verdict=FAIL
		note="capture failed: $err"
	elif [[ ! -s $src ]]; then
		verdict=FAIL
		note="the driver reported success but wrote no image"
	elif [[ $(gzip -9 <"$src" | wc -c) -lt $MIN_GZ_BYTES ]]; then
		verdict=REJECTED
		note="image is blank (compresses to under $MIN_GZ_BYTES bytes)"
	elif [[ $shot_url =~ $interstitial_re ]]; then
		# the browser's own final URL (the curl preflight is a different client and can
		# be let through where Zen is blocked, e.g. google's /sorry page); only the
		# part before any query or fragment is reported, the note cut to 200 characters
		verdict=REJECTED
		note="the browser ended at ${shot_url%%[?#]*} (consent wall, captcha or block page)"
		note=${note:0:200}
	elif [[ $pre_bad == 1 ]]; then
		verdict=REJECTED
		note=$pre_note
	fi
	if [[ $mode == full && -s $src ]]; then
		note="${note:+$note; }page ${full_h} px tall, shot as ${full_method:-?}"
		if [[ $full_cut == 1 ]]; then note="$note, CUT at $CAP_PX px"; fi
	fi
	note="${note:+$note; }${shot_secs}s"
	if [[ $verdict != ok && $verdict != skipped ]]; then log_failure "$name" "${err:-$note}"; fi
	if [[ $verdict != skipped && -s $src ]]; then
		dest=$name.png
		[[ $verdict == ok ]] || dest=$name.REJECTED.png
		local tmp
		tmp=$(mktemp ./.tmp.XXXXXX)
		cat -- "$src" >"$tmp"
		mv -f -T -- "$tmp" "$dest"
		read -r w h < <(png_dims "$dest")
		bytes=$(stat -c %s -- "$dest")
	fi
	[[ -z $shot_url ]] || final=${shot_url%%[?#]*}
	case $verdict in
	ok) n_ok=$((n_ok + 1)) ;;
	skipped) n_skip=$((n_skip + 1)) ;;
	REJECTED) n_rej=$((n_rej + 1)) bad=1 ;;
	*) n_fail=$((n_fail + 1)) bad=1 ;;
	esac
	note=$(printf '%s' "$note" | tr '\t\n' '  ')
	printf '%-10s %-14s %-9s %-24s %-9s %s\n' "$s" "$page" "$mode" "$state" "$verdict" "$note" >>"$report"
	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${dest:--}" "$s" "$page" "$final" "$state" "$mode" "$w" "$h" "$bytes" "$verdict" "$note" >>"$manifest"
	echo "theme-shots: $s/$page $mode $state: $verdict${note:+ ($note)}"
}

while IFS='|' read -r -u 3 s page url; do
	[[ -z $s || $s == \#* ]] && continue
	[[ $site == all || $site == "$s" ]] || continue

	# cheap interstitial check: where does a plain GET end up?
	res=$(clean curl -q -sS -L --proto =https --proto-redir =https --max-redirs 5 --max-time 25 -A "$UA" -o /dev/null \
		-w '%{http_code} %{url_effective}' "$url" 2>/dev/null </dev/null) || res="000 -"
	code=${res%% *}
	final=${res#* }
	pre_note=""
	pre_bad=0
	if [[ $final =~ $interstitial_re ]]; then
		pre_bad=1
		pre_note="a plain GET ends at $final (consent wall or captcha)"
	elif [[ $code =~ ^(4|5)[0-9][0-9]$ ]]; then
		pre_note="a plain GET got HTTP $code (Zen may differ; read the image)"
	elif [[ $code == 000 ]]; then
		pre_note="a plain GET got no HTTP answer (curl failed; the interstitial check did not run)"
	fi

	for state in RAW_no-userContent THEMED_with-userContent; do
		css=0
		[[ $state == THEMED_with-userContent ]] && css=1
		vname=$s-$page-viewport-$state
		fname=$s-$page-full-$state
		rm -f -- "$work/$vname.png" "$work/$fname.png"
		verr=""
		shoot "$url" "$css" "$work/$vname.png" "$work/$fname.png" || verr=${shot_err:-unknown}
		record viewport "$work/$vname.png" "$verr"
		record full "$work/$fname.png" "$full_err"
	done
done 3<"$URLS"

[[ ! -s $work/failures.txt ]] || cat -- "$work/failures.txt" >>"$report"
for f in userContent.css report.txt manifest.tsv; do
	src=$work/$f
	tmp=$(mktemp ./.tmp.XXXXXX)
	cat -- "$src" >"$tmp"
	mv -f -T -- "$tmp" "$f"
done

echo "theme-shots: summary: $n_ok ok, $n_rej rejected (kept as *.REJECTED.png), $n_fail failed, $n_skip skipped; wrote $(pwd -P) (PNGs, manifest.tsv, userContent.css, report.txt). Logged out, fresh profiles deleted. Images are untrusted input."
if [[ $bad == 1 ]]; then
	echo "theme-shots: some shots failed or were rejected; do not judge the theme from them (report.txt has the reason, timing and driver output tail for each)" >&2
	exit 4
fi
