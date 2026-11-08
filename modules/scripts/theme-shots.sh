# theme-shots SITE WORKTREE [OUTDIR]
#
# Before/after screenshots of google, youtube, reddit and instagram in a throwaway
# headless Firefox, with and without the Zen userContent.css this flake generates,
# so an agent can see which per-site rules (modules/theme/webstyling/*.nix) are
# broken. Packaged by modules/theme/theme-shots.nix and run as
# /run/current-system/sw/bin/theme-shots. Design, limits and trust assumptions:
# docs/agents/theme-shots.md and docs/agents/security.md ("theme-shots runs
# unsandboxed").
#
#   SITE     google | youtube | reddit | instagram | all
#   WORKTREE absolute path of a worktree under ~/.t3/worktrees/<project>/<name>
#   OUTDIR   inside <WORKTREE>/.log/ (default .log/theme-shots; relative paths are
#            relative to the worktree)
#
# SECURITY INVARIANT: this runs OUTSIDE the agent sandbox (sandbox.excludedCommands),
# as the owner, with the owner's network, and an agent chooses its three arguments.
# So nothing the caller supplies may choose a URL, a command, a Firefox flag or a
# path the script trusts:
#   - the URLs come from a fixed list in the Nix store (theme-shots-urls.txt);
#   - SITE is one of five words; WORKTREE must resolve to exactly
#     ~/.t3/worktrees/<project>/<name>, owned by the user, and the CALLER'S cwd must be
#     inside it (an agent's cwd is its own worktree, never another thread's); OUTDIR
#     must resolve (after symlinks) inside <WORKTREE>/.log/, and the script chdirs
#     into it with cd -P and re-checks the kernel's view of the cwd, so every write
#     uses a fixed file name in a directory it holds open (a swap between the checks
#     can still make mkdir create empty directories elsewhere, never write files);
#   - every child process gets a rebuilt environment (fixed PATH, passwd home, no
#     GIT_*/NIX_*/LD_*/PYTHON*/proxy/MOZ_* from the caller); Firefox gets its own
#     empty HOME, a fresh profile and a PAC file that sends everything except the
#     four sites' own hosts to a dead proxy (so generated CSS cannot reach
#     localhost, the LAN or other hosts over http(s); not file:, and the allowed
#     suffixes include hostable ones such as googleapis.com);
#   - the nix evaluation is pure (no --impure, --no-accept-flake-config). That is NOT
#     a read confinement: a flake can declare path:/git+file: inputs, IFD or hashed
#     fetches and read them as the owner, exactly as the already-excluded
#     `nix eval *` can. Do not rely on it as a boundary.
# Changing the argument parsing, the PAC list or the child environment is a tier-2
# review item.

URLS=@urls@
ATTR='nixosConfigurations.GOD-KILLER.config.home-manager.users.cairo.programs.zen-browser.profiles.default.userContent'
UA='Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0'
# Firefox's PNG encoder is weak (a blank 1400x1000 page is still ~27 KB), but gzip sees
# through it: blank 583 bytes, a flat page with two text lines 5.5 KB, a busy page 185 KB
# (measured 2026-11-08). Below this a shot is a blank page. It cannot tell a rendered
# block page or consent wall from a real one: the agent still has to look at the image.
MIN_GZ_BYTES=3000
# suffixes Firefox may reach (the sites and their asset CDNs); everything else is blackholed
ALLOWED_DOMAINS=(
	google.com gstatic.com googleapis.com googleusercontent.com
	youtube.com ytimg.com ggpht.com googlevideo.com
	reddit.com redditstatic.com redditmedia.com redd.it
	instagram.com cdninstagram.com fbcdn.net facebook.com facebook.net
)

die() {
	echo "theme-shots: $*" >&2
	exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || die "usage: theme-shots google|youtube|reddit|instagram|all WORKTREE [OUTDIR]"
site=$1
wt_arg=$2
out_arg=${3:-.log/theme-shots}

case $site in
google | youtube | reddit | instagram | all) ;;
*) die "unknown site '$site' (google|youtube|reddit|instagram|all)" ;;
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
[[ $out == "$wt"/.log/?* ]] || die "output dir must be inside $wt/.log/"

# create and enter the directory from the worktree root, checking the KERNEL's view of
# the directory we hold (readlink on /proc/self/cwd, not a path string that could be
# re-resolved after a symlink swap)
cd -P -- "$wt"
[[ $(readlink -f /proc/self/cwd) == "$wt" ]] || die "worktree changed under us"
[[ ! -L .log ]] || die ".log is a symlink"
mkdir -p -- "${out#"$wt"/}"
cd -P -- "${out#"$wt"/}"
[[ $(readlink -f /proc/self/cwd) == "$out" ]] || die "output dir left $wt/.log/ (symlink swapped?)"

work=$(mktemp -d /tmp/theme-shots.XXXXXX)
cleanup() {
	[[ -n ${work:-} ]] && rm -rf -- "$work"
}
trap cleanup EXIT

# rebuilt environment for every child; the caller's is never passed on
clean() {
	env -i "PATH=$PATH" "HOME=$home" "USER=$user" "LOGNAME=$user" "LANG=C.UTF-8" \
		"SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" "$@"
}

echo "theme-shots: evaluating userContent from $wt (GOD-KILLER)"
if ! clean timeout 900 nix eval --raw --no-write-lock-file --no-accept-flake-config "git+file://$wt#$ATTR" \
	>"$work/userContent.css" 2>"$work/nix.err" </dev/null; then
	echo "theme-shots: nix eval failed:" >&2
	tail -n 20 "$work/nix.err" >&2
	echo "theme-shots: files that are not git-added are invisible to the flake (git add the new ones)" >&2
	exit 3
fi
grep -q '@-moz-document' "$work/userContent.css" || die "evaluated userContent has no @-moz-document rule; refusing to continue"

# PAC: only the four sites' own hosts go direct, everything else (localhost, the LAN,
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

# one fresh profile + HOME per shot; $1 = with CSS (1) or not (0)
make_profile() {
	local prof=$1 css=$2
	mkdir -p -- "$prof/chrome"
	cat >"$prof/user.js" <<EOF
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
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

shoot() { # $1 = url, $2 = css (0|1), $3 = png path
	local iso
	iso=$(mktemp -d "$work/iso.XXXXXX")
	mkdir -p -- "$iso/tmp"
	make_profile "$iso/profile" "$2"
	env -i "PATH=$PATH" "HOME=$iso" "USER=$user" "LANG=C.UTF-8" "TMPDIR=$iso/tmp" \
		"XDG_CONFIG_HOME=$iso/config" "XDG_CACHE_HOME=$iso/cache" "XDG_DATA_HOME=$iso/data" \
		"FONTCONFIG_FILE=/etc/fonts/fonts.conf" "MOZ_HEADLESS=1" \
		timeout --kill-after=10 120 firefox --headless --no-remote --profile "$iso/profile" \
		--window-size 1400,1000 --screenshot "$3" "$1" >"$iso/firefox.log" 2>&1 </dev/null
}

interstitial_re='^https?://(consent\.[^/]+/|[^/]+/(sorry|consent|captcha|challenge)([/?]|$))'
bad=0
report=$work/report.txt
printf '%-10s %-8s %-7s %-9s %s\n' site page phase verdict note >"$report"

while IFS='|' read -r -u 3 s page url; do
	[[ -z $s || $s == \#* ]] && continue
	[[ $site == all || $site == "$s" ]] || continue

	# cheap interstitial check: where does a plain GET end up?
	res=$(clean curl -sS -L --proto =https --proto-redir =https --max-redirs 5 --max-time 25 -A "$UA" -o /dev/null \
		-w '%{http_code} %{url_effective}' "$url" 2>/dev/null </dev/null) || res="000 -"
	code=${res%% *}
	final=${res#* }
	pre_note=""
	pre_bad=0
	if [[ $final =~ $interstitial_re ]]; then
		pre_bad=1
		pre_note="a plain GET ends at $final (consent wall or captcha)"
	elif [[ $code =~ ^(4|5)[0-9][0-9]$ ]]; then
		pre_note="a plain GET got HTTP $code (Firefox may differ; read the image)"
	fi

	for phase in before after; do
		css=0
		[[ $phase == after ]] && css=1
		name=$s-$page-$phase
		rm -f -- "$name.png" "$name.REJECTED.png"
		verdict=ok
		note=$pre_note
		if ! shoot "$url" "$css" "$work/$name.png"; then
			verdict=FAIL
			note="firefox failed or timed out"
		elif [[ ! -s $work/$name.png ]]; then
			verdict=FAIL
			note="firefox wrote no image"
		elif [[ $(gzip -9 <"$work/$name.png" | wc -c) -lt $MIN_GZ_BYTES ]]; then
			verdict=REJECTED
			note="image is blank (compresses to under $MIN_GZ_BYTES bytes)"
		elif [[ $pre_bad == 1 ]]; then
			verdict=REJECTED
			note=$pre_note
		fi

		if [[ -s $work/$name.png ]]; then
			dest=$name.png
			[[ $verdict == ok ]] || dest=$name.REJECTED.png
			tmp=$(mktemp ./.tmp.XXXXXX)
			cat -- "$work/$name.png" >"$tmp"
			mv -f -T -- "$tmp" "$dest"
		fi
		[[ $verdict == ok ]] || bad=1
		printf '%-10s %-8s %-7s %-9s %s\n' "$s" "$page" "$phase" "$verdict" "$note" >>"$report"
		echo "theme-shots: $s/$page $phase: $verdict${note:+ ($note)}"
	done
done 3<"$URLS"

for f in userContent.css report.txt; do
	src=$work/$f
	tmp=$(mktemp ./.tmp.XXXXXX)
	cat -- "$src" >"$tmp"
	mv -f -T -- "$tmp" "$f"
done

echo "theme-shots: wrote $(pwd -P) (report.txt, userContent.css and the PNGs; REJECTED shots are kept under *.REJECTED.png)"
if [[ $bad == 1 ]]; then
	echo "theme-shots: some shots failed or were rejected; do not judge the theme from them" >&2
	exit 4
fi
