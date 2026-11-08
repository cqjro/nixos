# theme-shots and zen-shots: seeing the per-site Zen theme

Ground truth for the Zen per-site theming. Every `modules/theme/webstyling/*.nix`
fragment sets `zenWebStyling.siteStyles.<domain>`; `home-manager/apps/zen-browser.nix`
wraps each in `@-moz-document domain("<domain>")` and appends it to the generated
`userContent.css`. Those rules target classes the sites rotate, so they break
silently. `theme-shots` shows an agent what a rule does today.

| Tool | Who runs it | What it does |
| --- | --- | --- |
| `theme-shots` | agents (excluded from the sandbox, allow-listed) | headless, **logged-out** Firefox; before and after the generated CSS |
| `zen-shots` | **the human only** (the policy denies it for agents) | the real, logged-in Zen under Hyprland; `grim` of the active window |

Both are installed system-wide by `modules/theme/theme-shots.nix` (GOD-KILLER
only), so they exist after a **GOD-KILLER switch** of the PR that adds them.
Both read one fixed page list, `modules/scripts/theme-shots-urls.txt`, from the Nix
store: google search results, youtube home and a watch page, reddit home and a post,
instagram login.

## `theme-shots` (agents)

```
/run/current-system/sw/bin/theme-shots SITE WORKTREE [OUTDIR]
```

- `SITE`: `google`, `youtube`, `reddit`, `instagram` or `all`. Nothing else is
  accepted; there is no way to pass a URL.
- `WORKTREE`: the **absolute** path of your worktree
  (`/home/cairo/.t3/worktrees/.nixos/<name>`); `pwd` gives it.
- `OUTDIR`: optional, must end up inside `<WORKTREE>/.log/` (default
  `.log/theme-shots`; a relative path is relative to the worktree). `.log/` is
  gitignored.

Call it as **one plain command with the absolute path**: no `cd … &&`, no pipe, no
redirect, no `timeout`/`VAR=` prefix (the exclusion only matches the plain command and
the guard blocks anything else naming the path). Each shot takes ~10 to 30 s, so `all`
(12 shots) can run several minutes: run one site at a time, or pass a longer `timeout`
to the Bash tool. New files must be `git add`ed first: the flake only sees tracked
files.

What it does, in order:

1. `nix eval --raw git+file://<worktree>#nixosConfigurations.GOD-KILLER.config.home-manager.users.cairo.programs.zen-browser.profiles.default.userContent`
   (pure: no `--impure`), so it renders **your branch's** CSS, not the switched one.
2. For every page of the site, twice (`before`, `after`): a fresh throwaway Firefox
   profile and an empty HOME, `user.js` with
   `toolkit.legacyUserProfileCustomizations.stylesheets`, `ui.systemUsesDarkTheme=1`,
   `layout.css.prefers-color-scheme.content-override=0`; the `after` profile also gets
   `chrome/userContent.css`, the `before` one does not. Then
   `firefox --headless --no-remote --profile P --window-size 1400,1000 --screenshot OUT URL`.
3. Writes into `OUTDIR`: `<site>-<page>-before.png`, `<site>-<page>-after.png`,
   `userContent.css` (exactly what was injected) and `report.txt` (one line per shot).

Read the PNGs with the Read tool and compare `before` and `after`; the CSS in
`userContent.css` tells you which rule should have hit.

Exit codes: `0` all shots fine, `2` bad arguments, `3` the nix evaluation failed (its
last lines are printed), `4` at least one shot failed or was rejected.

### Limits (read before trusting a shot)

- **Logged out only.** No account, no cookies, no extensions: no uBlock, Dark Reader
  or Stylus, which the real Zen has, so the page is the unblocked, unthemed-by-extensions
  site. What a logged-in feed looks like is `zen-shots`' job.
- **Instagram is the login page only** (everything else is behind a login).
- **Captures at the load event.** A page that renders its content late (YouTube home
  is a JS app) can come out as a skeleton. If an `after` shot is missing content
  that the `before` shot has too, that is the capture, not the CSS.
- **Interstitials.** Consent walls, "unusual traffic" pages and bot blocks (Reddit and
  Google are the usual ones) are served by the site, not by this tool. Detection is
  cheap and incomplete, and a shot that fails it is **not written under its normal
  name**: it is kept as `<name>.REJECTED.png` and the run exits `4`:
  - a plain `curl` GET of the URL (same fixed list) that ends on a `consent.*` host or
    a `/sorry`, `/consent`, `/captcha` or `/challenge` path;
  - a blank image (its PNG gzips to under 3000 bytes).

  Not detected: a block or consent page that renders as ordinary text. Always look at
  the image. A curl HTTP 4xx/5xx is only a note in `report.txt` (Firefox may be let in
  where curl is not), not a rejection.
- **Network confinement.** Firefox gets a PAC file that sends only the four sites and
  their asset CDNs (`google.com gstatic.com googleapis.com googleusercontent.com
  youtube.com ytimg.com ggpht.com googlevideo.com reddit.com redditstatic.com
  redditmedia.com redd.it instagram.com cdninstagram.com fbcdn.net facebook.com
  facebook.net`) direct and everything else to a dead proxy. A site that starts
  using another host loses that asset (the page still loads: blocked subresources fail
  at once). If the *document* itself redirects to an unlisted host the shot times out
  (`firefox failed or timed out`); add the host to `ALLOWED_DOMAINS` in
  `modules/scripts/theme-shots.sh`, as a tier-2 item (below).
- **Unverified until the first real run.** The sandbox cannot reach these sites, so
  the live pages, the reddit post URL and the PAC against the real hosts were not
  exercised. Verified in the sandbox against a local server: argument validation and
  symlink refusal, the profile and `userContent.css` injection (a visible before/after
  difference), the PAC (a blackholed host gets no connection, an allowed one loads), a
  blank page and a consent redirect each rejected with exit 4.

### Trust assumptions (it runs outside the sandbox)

The full reasoning is in [security.md](security.md#theme-shots-runs-unsandboxed). In
short, an agent chooses three arguments and the script runs as the owner with the
owner's network, so it accepts only: five site words; a worktree under
`~/.t3/worktrees/` owned by the owner; an output dir that resolves inside that
worktree's `.log/` (checked, then re-checked on the directory it `chdir`s into).
URLs, Firefox flags and prefs come from the script. Changing any of that, the PAC
list or the child environment is a tier-2 review item.

## `zen-shots` (the human)

Agents never run this: the managed policy denies `zen-shots`, and it needs your
Wayland/Hyprland session. Run it from a terminal **inside the worktree the agent is
using**, so the images land where its sandbox can read them:

```
cd ~/.t3/worktrees/.nixos/<worktree>
zen-shots              # all sites into ./.log/zen-shots
zen-shots youtube      # one site
zen-shots all some/dir # another directory (relative to here)
ZEN_SHOTS_WAIT=20 zen-shots reddit   # seconds to let each page settle (default 12)
```

For each page it focuses the Zen window (`hyprctl dispatch focuswindow
class:zen-twilight`), opens the URL with `zen-twilight` (a new tab in your running Zen),
waits, checks the active window really is Zen, and `grim`s that window to
`<site>-<page>.png`. It refuses to shoot any other window, then refocuses what you were
on. Do not touch the keyboard or mouse while it runs.

**These are your logged-in pages** (recommendations, avatar, notification badges).
They go under `.log/` (gitignored: never `git add -f` them). Open the folder and delete
what you do not want an agent to read before telling it the images are there. Tell the
agent the path, e.g. `.log/zen-shots/`; it reads them with the Read tool.

*Built and shellchecked, not run*: it needs your compositor session, so the first run
is yours. If a shot comes out of the wrong window or a blank one, raise
`ZEN_SHOTS_WAIT` first.

Because it uses your real Zen, the shots include your extensions (uBlock, Dark Reader,
Stylus) and the **switched** theme, not the branch's: until a branch is switched or the
CSS is added to your live Zen another way, `zen-shots` shows the old rules. Compare with
`theme-shots`' `after` for the branch.
