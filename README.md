# NixOS Config

My personal NixOS configuration, managed as a Git flake and spread across three
machines. Everything — desktop shell, terminal, apps, websites, even Discord and
Spotify — is themed from a single base16 palette via [Stylix](https://github.com/danth/stylix).

## Table of Contents

- [Machines](#machines)
- [Repository Layout](#repository-layout)
- [Planned Updates](#planned-updates)
- [The Dendritic Pattern](#dendritic-pattern)
- [Theming](#theming)
- [Key Features](#key-features)
- [AI agents](#ai-agents)
- [Xbox Game Pass (Xodus Nexus)](#xbox-game-pass-xodus-nexus)
- [Pending upstream fixes](#pending-upstream-fixes)
- [Scripts](#scripts)
- [Installation](#installation)
- [Change workflow](#change-workflow)

## Machines

Three hosts are defined in `modules/hosts/host.nix`, each a near-complete
NixOS configuration that picks and chooses its modules from the pool:

| Host | Hardware | Role |
| --- | --- | --- |
| `GOD-KILLER` | AMD desktop, NVIDIA GPU, dual 4K monitors (BenQ + MSI OLED) | Main workstation: full Hyprland desktop, gaming, media |
| `LittleNix` | Apple T2 MacBook (`nixos-hardware` `apple-t2`) | Laptop desktop, touchbar, mobile spicetify/discord |
| `REDRUM` | Apple T2 MacBook | Headless server (no DE): Tailscale, Paperless-ngx, Actual Budget, Linkwarden, Beszel, Glance, Homepage dashboard, Cloudflared, YouTube automation |

`REDRUM` is built against a **pinned nixpkgs** (`cac0c1ef`) because `linux >= 6.18.47`
breaks the t2linux patchset on the T2 Macs. See `modules/hosts/REDRUM/T2-PIN.md`
for details and the TODO for when it can be unpinned, and
[Pending upstream fixes](#pending-upstream-fixes) for the full list of
workarounds currently in the tree. Packages that have to track upstream security
fixes are overridden explicitly — currently `cloudflared`
(`services.cloudflared.package` in `modules/server/cloudflared.nix` pins
Cloudflare's release binary, since the pinned nixpkgs lags the tunnel's security
releases) and `tailscale` (`services.tailscale.package` in
`modules/server/tailscale.nix` pins 1.104.4, since the pinned nixpkgs ships
1.102.2 and its Go toolchain is too old to build 1.104.4) and `t3code`
(`modules/server/t3code.nix` runs the server from the main `nixpkgs` input, since
the desktop client rejects the pinned nixpkgs' older 0.0.33 server).

## Repository Layout

```
flake.nix              # Flake inputs (flake-parts + import-tree scaffolding)
rebuild.sh             # Staged rebuild (check/eval/build/test/switch/push/generations) + interactive flow
AGENTS.md              # Shared agent guidance (CLAUDE.md imports it for Claude Code)
.claude/               # Reviewer subagents and workflow skills (start-todo, ship-pr, merge-pr)
.github/               # Pull request template
start.sh               # Startup script run by Hyprland: loads the SSH agent (no config pull)
TODO.md                # Planned updates to the config (wishlist, not tracked as issues)
docs/agents/           # On-demand agent reference: workflow, review tiers, recipes, registry, gotchas
docs/secrets.md          # Secrets audit, rotation runbook, secrets design (sops-nix deferred), T3 request_secret, secret-guard hooks
docs/waydroid/         # Android TV (Waydroid) plan, spike notes and pinned image info

modules/
├── _archive/          # Retired / superseded modules (kept for reference)
├── essentials/        # System services: networking, dbus, bluetooth, audio, printing, users, keyring, nvidia...
├── hosts/             # Per-machine config:
│   ├── host.nix       #   Assembles all nixosConfigurations
│   ├── GOD-KILLER/    #   machine.nix / home.nix / hardware.nix / monitors.nix
│   ├── LittleNix/
│   └── REDRUM/        #   (incl. T2-PIN.md)
├── home-manager/      # User-level config
│   ├── ai-tools/      #   claude-code (permissions), mcp-servers (mcp-nixos), t3code, github-cli
│   ├── apps/          #   3d-printing, calibre, dwsim, millennium, mpv, nemo, nixdatifier, spicetify, xodus-nexus, zen-browser, ...
│   ├── desktop/       #   hyprland, gtk, noctalia-shell, walker, ...
│   ├── keyboard/      #   xremap (powerful key remaps + app launching)
│   ├── languages/     #   latex, language toolchains
│   └── terminal/      #   zsh, ghostty, nvim, starship, yazi, btop, nom, ...
├── scripts/           # Helper scripts (window focus, pip move, keybind cheatsheet)
├── server/            # REDRUM services: paperless, beszel, glance, homepage, actual-budget, linkwarden, miniflux, reactflux, cloudflared, tailscale, youtube
├── system/            # System-level config: games, minecraft, waydroid, ios-sideloading, tether, flatpak, rss-sources, vpn...
└── theme/             # Everything color-related
    └── webstyling/    #   Per-site CSS themes for the browser
```

## Planned Updates

[`TODO.md`](TODO.md) lists planned updates to this configuration — features
and improvements that are wanted but not yet implemented (system-level items
like Waydroid/Android TV, and REDRUM server additions such as Immich and
Pi-hole). It is a working checklist, not a roadmap or issue tracker; items
are removed from it once they land in the tree.

## The Dendritic Pattern

The whole config is organised around a "dendritic" (tree-branching) module
pattern built from three pieces:

1. **[flake-parts](https://flake.parts)** — provides the `flake.modules` option
   namespace, so modules can declare fragments in a structured way instead of
   appending to a flat `imports` list.
2. **[import-tree](https://github.com/vic/import-tree)** — recursively imports
   *every* `.nix` file under `modules/` with zero boilerplate. Adding a new
   file to any directory just works; there is no registry to update.
3. A small convention: each file that wants to expose something declares, at its
   top level,

   ```nix
   flake.modules.nixos."some-module" = { pkgs, ... }: { ... };            # system config
   flake.modules.homeManager."some-module" = { config, ... }: { ... };    # user config
   ```

Hosts then *compose* these fragments explicitly in `host.nix` (system level)
and in each host's `machine.nix` (home-manager level):

```nix
inputs.self.modules.nixos."$name"             # system modules
inputs.self.modules.homeManager."$name"       # user modules
```

Each file is a small, self-contained fragment ("detritus") that does one thing.
Adding a feature to one or two machines is just a matter of adding its name to
that host's import list. Unused fragments are simply never referenced.

## NUR packages removed

All Nix User Repository (NUR) inputs, modules, and NUR-sourced packages have been removed from this configuration. NUR packages can be removed at any time and may require finding new sources or packaging them differently.

## Theming

Colour is defined exactly once in `modules/theme/stylix.nix` as a hand-tuned
base16 scheme (dark, deep purple base, green/cyan/blue/orange accents) and
propagated everywhere by **Stylix** with `autoEnable`, plus a few hand-rolled
targets:

- **Hyprland** — active window border and shadows derive from `base05`; cursor
  theme is Rose Pine (BreezeX).
- **Zen Browser** — `userChrome.css` / `userContent.css` generated from the
  palette (see `home-manager/apps/zen-browser.nix`), plus the per-site CSS in
  `theme/webstyling/*.nix` which restyles *every* page — YouTube, Reddit,
  Google, GitHub, Wikipedia, Instagram, Brave, Claude, and nixpkgs — from the
  `@-moz-document` block in the browser's `userContent.css`.
- **Discord** — a two-hundred-line `quickCss` (via nixcord) remaps every Discord
  CSS variable to the base16 palette: flat `base00` background, `base01`/`base02`
  elevation, `base03` borders, `base05` text, `base0D` brand blue. Applied to
  both nixcord clients — **Vesktop** (`vesktop` + Vencord) and the standalone
  **Discord** package.
- **Spotify** — spicetify with a generated `color.ini` (same mapping) instead of
  a pre-baked theme, so it always matches.
- **Steam** — the **Millennium** client patch with the same palette mapping;
  toggled globally via `manifest.enableMillennium` / `manifest.enableSpicetify`
  (`modules/system/manifest.nix`).
- **OpenRGB** — systemd service for motherboard/mouse lighting.

### Actual Budget theming

Actual Budget runs on REDRUM behind the **Actual Budget Tweaks** (ABT) sidecar
(`modules/server/actual-budget-tweaks.nix`), a small reverse proxy that injects
ABT's UI tweaks into every browser that opens `budget.cqjro.ca` — no extension
needed. ABT themes the app from a set of `--ctp-*` CSS tokens, so the sidecar
seeds it with a palette derived from the shared Stylix base16 scheme: Actual
matches the rest of the config out of the box.

- **Switching themes is live.** Open ABT's settings → **Theme Customizer** and
  pick **Native** (Actual's own default look), **Stylix** (the generated
  palette), or any of ABT's built-in/community themes. Your pick is remembered
  and synced into the budget, so it follows you across browsers and devices.
- **The Stylix seed is only a default.** The sidecar writes `user:stylix` into
  ABT's theme storage and selects it only when no theme has ever been chosen;
  it never overrides a later choice.
- **Turning it off entirely.** `services.abt-sidecar.stylixTheme = false`
  (set in `modules/hosts/host.nix`, next to `services.abt-sidecar.enable`)
  drops the Stylix shim and leaves Actual on its stock theme. The seed lives in
  `modules/scripts/abt-browser-shim.js` (the upstream shim plus the seed); the
  base16 → ABT token map is built NixOS-side in `actual-budget-tweaks.nix`.

## Key Features

- **Hyprland** with a **Lua config** (`configType = "lua"`), per-monitor
  declarations parsed from `desc:` strings, disabled borders with soft glow
  shadows, custom bezier curves and animation tuning, and full window/bindings
  via a small Nix → Lua DSL.
- **noctalia** — a full shell bar/panel system (dock, control centre, media
  OSD, widgets, clipboard, session control) controlled through the CLI.
- **Walker** — GTK launcher (Rofi-style) with a fully stylix-themed stylesheet.
- **xremap** — Caps↔Esc/Super remap plus an extensive layered keymap:
  `Super+O` focuses-or-launches your apps (terminal, nvim, browser, mail,
  discord…), `Super+M/B/V/R/L/A/S/D/C/K` drive media, volume, brightness,
  sessions, panels and screenshots through `noctalia`.
- **Zen Browser** (twilight) — managed profiles with pinned tabs *per workspace*
  (`Entertainment`, `Nix`, `Browsing`), container isolation, ublock-origin /
  Proton Pass / Dark Reader / Stylus, and the webstyling stack above.
- **Server stack on REDRUM** — Tailscale, Paperless-ngx (paperless storage, tied to
  the stylix `glance` theme only for the glance dashboard), Actual Budget
  (self-hosted finance) with **Actual Budget Tweaks** (a sidecar proxy that
  injects UI tweaks and is seeded with the Stylix palette — see
  [Actual Budget theming](#actual-budget-theming)), Linkwarden (bookmarks), Beszel (server monitoring),
  Glance (feed dashboard, themed by Stylix), Miniflux (RSS reader) with
  ReactFlux (a Miniflux web client), a T3 Code agent server (tailnet-only, see [T3 Code on REDRUM](#t3-code-on-redrum)), a Cloudflare-hosted homepage
  (with a Homelab tab listing every exposed app), and a systemd YouTube
  playlist-sync service (hourly; reads subscriptions via the Data API but checks
  each channel's RSS feed for new uploads to stay under the daily API quota)
  backed by a `devShell` (`nix develop .#youtube-sync`).
- **System niceties** — Opt-in experimental features, auto-optimised store,
  Flatpak support, Minecraft + game launchers, Waydroid, iOS sideloading
  toolchain, `mtkclient`/`rockbox-utility` gadget firmware "doodads", VPN, and
  printing.
- **Tether** — iPhone ↔ Linux bridge on the desktop hosts (GOD-KILLER and
  LittleNix): notification mirroring (ANCS), SMS/iMessage + contacts
  (MAP/PBAP) over Bluetooth, plus clipboard sync, file transfer and OTP
  handling over Wi-Fi via the iOS app. Defined in `modules/system/tether.nix`
  (wraps `github:zackb/tether`'s NixOS module). See the pairing steps below.
- **Shared rss sources** — `rss-sources` (`modules/system/rss-sources.nix`)
  defines the standard feed list once; the glance rss widget and the `nom`
  terminal reader both consume it, so the same sources appear everywhere. The
  list itself is data, `modules/system/rss-feeds.json` (`url`, `title`, optional
  `category`, `tags`, `limit`), and the module also renders it as OPML, linked
  at `/etc/rss-sources.opml` — import that file into any reader (FreshRSS, Yarr,
  NetNewsWire, …) to bulk-subscribe. `category` becomes the folder/category in
  readers that have one (Miniflux's "Nuclear" holds the nuclear-industry feeds).
  - **Miniflux sync (list → Miniflux, automatic)** — the REDRUM unit
    `miniflux-rss-sync` (`modules/server/miniflux-rss-sync.nix`) subscribes
    Miniflux to every feed in the list, creating categories such as "Nuclear".
    It runs on the REDRUM switch that changes the list (and at boot), as the
    `miniflux` user over loopback, authenticating with a Miniflux API key kept
    in `/var/lib/miniflux/api-token` (create it once, see "Create app secrets";
    the unit logs `no API key` / `401` until it exists and is valid, and the
    switch still succeeds).
    By default it only adds: a feed you deleted in Miniflux is not re-added (the unit keeps
    `/var/lib/miniflux/rss-sync-snapshot.json`, the URLs it already pushed), and
    a feed that fails to subscribe is retried on the next run. Check it with
    `systemctl status miniflux-rss-sync` / `journalctl -u miniflux-rss-sync`;
    rerun with `sudo systemctl restart miniflux-rss-sync`. Setting
    `miniflux-rss-sync.prune = true` also deletes feeds you drop from the list
    (and their entries); it is off by default, never touches feeds added from a
    phone, and refuses to prune more than 5 feeds (or anything when the list is
    empty) in one run. Rotating your Miniflux login does not affect it; only
    revoking the API key does.
  - **Miniflux → list (manual)** — `rss-sync` on GOD-KILLER
    (`modules/scripts/rss-sync.py`, `home-manager/terminal/rss-sync.nix`) is for
    the reverse direction, and every command is a dry run until given its flag:

    | Command | Effect |
    | --- | --- |
    | `rss-sync` / `rss-sync status` | what is new or removed on each side |
    | `rss-sync pull --write` | add feeds you subscribed to in Miniflux/on your phone to the list |
    | `rss-sync pull --write --apply-removals` | also drop feeds you deleted in Miniflux from the list (refuses more than 5 at once, or if Miniflux is empty) |

    `pull` only edits the JSON (and `rss-feeds.synced.json`, its own snapshot of
    URLs both sides agreed on); commit it and rebuild so Glance/`nom`/the OPML
    pick it up. It needs an API token for `https://feed.cqjro.ca` (override with
    `MINIFLUX_URL`): create one in Miniflux (Settings → API Keys), then run
    `mkdir -p ~/.config/rss-sync` and, one line at a time, `printf 'API key: ';
    read -rs v; echo; printf '%s' "$v" | install -m 600 /dev/stdin
    ~/.config/rss-sync/api-token; unset v` (or export `MINIFLUX_TOKEN`).
    `push` and `prune --yes` also exist but are the unit's
    job; running them by hand on GOD-KILLER uses a different snapshot than the
    unit. A feed whose URL Miniflux rewrites after a permanent redirect shows up
    as one deletion plus one addition; `pull --write --apply-removals` resolves
    it. With `prune` off, a feed removed from the list but still in Miniflux is
    offered back by `pull`; delete it in Miniflux (or enable `prune`) to stop that.

- **Nixdatifier** — NixOS generations, package diffs, flake-update checks and
  store tools from the desktop: the tray app's icon lives in noctalia's bar
  tray (a click toggles the window), a 6h background timer notifies when flake
  inputs are outdated, and the same package ships the `nixdatifier` CLI/TUI
  (installed CLI-only on REDRUM). Its TUI theme is generated from the Stylix
  palette. Every rebuild merges a declarative slice into the widget's
  `~/.config/nixdatifier/standalone.json` and restarts the tray app (flake
  path `~/.nixos`, 20 generations, font scale 1.3, palette colours); all
  other widget settings stay app-owned and survive rebuilds. From
  `github:Muddyblack/nixdatifier` via
  `modules/home-manager/apps/nixdatifier.nix` — not in nixpkgs yet.
- **Xbox Game Pass** — [Xodus Nexus](https://github.com/domsvoboda/xodus-nexus),
  an Xbox-style launcher for Microsoft Store / PC Game Pass titles, installed on
  `GOD-KILLER` via `modules/home-manager/apps/xodus-nexus.nix`. The launcher
  downloads its Xodus backend and Nexus runtime on first run (see
  [Xbox Game Pass (Xodus Nexus)](#xbox-game-pass-xodus-nexus)).
- **DWSIM** — [DWSIM](https://dwsim.org), an open-source chemical process
  simulator, repackaged from the official `.deb` release (not in nixpkgs) by
  `modules/home-manager/apps/dwsim.nix` on `GOD-KILLER`. The version and hash
  are the `dwsim.version` / `dwsim.hash` options; `modules/scripts/dwsim-update.sh`
  prints the latest pair.
- **3D printing** — a slicer + modelling toolchain on the desktop hosts
  (GOD-KILLER, LittleNix): **QIDI Studio** as the slicer for QIDI printers
  (a Bambu Studio / PrusaSlicer fork), plus **FreeCAD** and **SolveSpace** for
  parametric CAD, **OpenSCAD** for script-driven solids and **Blender** for mesh
  work — installed via `modules/home-manager/apps/3d-printing.nix`. All are from
  nixpkgs; QIDI Studio is locally re-wrapped to fill gaps in its FHS env
  (`libsoup_3`/`libpng`, the CA bundle, and the GIO TLS backend) and its webview
  User-Agent is patched so online-model login works, until upstream addresses
  both (see [Pending upstream fixes](#pending-upstream-fixes) rows 2 and 3).

## AI agents

`GOD-KILLER` runs coding agents through [T3 Code](https://github.com/pingdotgg/t3code)
(`modules/home-manager/ai-tools/t3code.nix`, themed from Stylix) driving Claude
Code, with `gh` for GitHub. T3 Code's window snapshots work on Hyprland because
`t3code.nix` builds the native capture helper (nixpkgs does not; see
[Pending upstream fixes](#pending-upstream-fixes) row 9) and `hyprland.nix` binds
`CTRL + SHIFT + 2` to its global shortcut. Everything is declared in
`modules/home-manager/ai-tools/`:

- **Permissions** (`claude-code.nix`, fragment `claude-code-policy`) — one
  managed policy for GOD-KILLER and REDRUM in
  `/etc/claude-code/managed-settings.json`, which agents cannot edit. Bash runs
  in a bubblewrap sandbox that hides your home directory and limits the network
  to GitHub and nixos.org; secrets and the T2 firmware are denied; a
  `claude-guard` hook blocks dangerous commands (secret paths, `curl | sh`,
  force pushes, `tailscale serve`, firmware reads). Branch commits, `gh pr
  create` and `rebuild.sh check|eval|build` run without a prompt; `sudo`,
  `rebuild.sh switch|test|push`, `git push`, commits on `master` and `gh pr
  merge` ask. Only hooks from the managed policy run. A second hook,
  `secret-guard`, blocks a message or tool call that carries a key or token and
  guards the T2 firmware paths (on GOD-KILLER and REDRUM; `docs/secrets.md`).
  Full access keeps the sandbox, denies and guard but refuses every `ask`
  instead of prompting.
  Detail and the smoke test: [`docs/agents/security.md`](docs/agents/security.md).
- **mcp-nixos** (`mcp-servers.nix`) — real NixOS / Home Manager / nixpkgs
  package, option and version data over MCP instead of guessed attribute names,
  delivered to Claude Code via `programs.mcp` + `enableMcpIntegration`.
- **Rebuilds** — agents run `./rebuild.sh check|eval|build HOST` freely (silent
  on success without a terminal; the log is `.log/nixos-build.log`).
  `test`/`dry`/`switch` need your approval in T3 *and* your password in a GUI
  dialog. Remote hosts (REDRUM) are built by the agent but activated by you in
  a terminal. See [Change workflow](#change-workflow).
- **Agent docs** — `AGENTS.md` is the shared guide for any agent; `CLAUDE.md`
  imports it (`@AGENTS.md`) and adds Claude-only notes; long reference material
  is in `docs/agents/` and is read on demand, keeping per-thread context small.
- **Reviewers and skills** (`.claude/`) — read-only reviewer subagents
  (`nix-reviewer` on Haiku, `lockout-reviewer` on Sonnet for network/SSH/boot
  changes, `deep-reviewer` on Opus as an escalation) and the `start-todo`,
  `ship-pr` and `merge-pr` skills that drive the PR workflow.
- **Pushing** (`github-cli.nix`) — `gh` is git's credential helper over HTTPS,
  so an approved `git push` works from an agent thread without an SSH agent or
  access to `~/.ssh`. The `origin` remote must be
  `https://github.com/cqjro/nixos.git` (`git remote set-url origin …`, one-time,
  not in Nix). Commands that would print the token (`gh auth token`,
  `git credential*`, anything touching `hosts.yml`) are denied, but a push you
  approve still uses your token — consider a fine-grained PAT limited to this
  repo if you want a smaller blast radius.
- **One-time setup in T3** — Settings → Threads → New threads → Permissions →
  **Accept edits** (T3 defaults to Full access, which refuses every `ask` rule);
  pick Supervised per thread for policy, secrets or networking work.
- **Notifications** (`notifications.nix`, fragment `agent-notifications`) — approval,
  completion and failure alerts through `claude-code-policy.hooks`: desktop popups on
  GOD-KILLER, ntfy push to a phone on both hosts (ntfy only on REDRUM). Setup and
  tests in [`docs/notifications.md`](docs/notifications.md).

## Xbox Game Pass (Xodus Nexus)

`GOD-KILLER` installs [Xodus Nexus](https://github.com/domsvoboda/xodus-nexus)
from `modules/home-manager/apps/xodus-nexus.nix`: an Xbox-style launcher for
Microsoft Store and PC Game Pass games that runs them through a shared
Proton-based runtime (no Windows install).

- **What Nix installs** is only the launcher AppImage. On first launch open
  **Settings → Xodus backend → Install backend**, then **Settings → Nexus
  runtime → Install Nexus runtime**. Those downloads are the patched upstream
  Xodus components and live in the user data directory, not the Nix store.
  The launcher itself is version-pinned in the module; bump `version` (and
  `hash`) there to update it.
- **Sign-in** needs an unlocked keyring, provided by the shared `keyring`
  module (`modules/essentials/keyring.nix`: `gnome-keyring` plus greetd PAM
  unlocking, also used by T3 Code's saved connections). If passkey sign-in hangs, use
  **Continue in browser**, which requires Google Chrome (not Chromium/Firefox).
- **Requirements:** a Microsoft account with a valid purchase or Game Pass
  subscription. Compatibility varies by game; see the upstream list.

## Pending upstream fixes

Workarounds currently in the tree because of bugs or gaps **upstream**. Each
entry is a deliberate, temporary reduction in scope — re-check it whenever a
rebuild conversation starts, and drop the workaround once the upstream fix
lands. Keep this list in sync with the agent copy in
`docs/agents/upstream-registry.md` (`./rebuild.sh check` compares the row
numbers), and add a row here in the same commit that introduces a new
workaround.

| # | Workaround | Where | Blocked on | Re-enable when |
| --- | --- | --- | --- | --- |
| 1 | REDRUM built from a pinned nixpkgs (`cac0c1ef`, kernel 6.18.46) instead of `nixpkgs/nixos-unstable` | `flake.nix:18`, `modules/hosts/host.nix:91`, `modules/hosts/REDRUM/T2-PIN.md` | `NixOS/nixos-hardware#2027` — `linux_6_18 >= 6.18.47` rejects the `facf1c7` t2linux patchset | the issue is resolved (or the pin is otherwise obsolete); full removal steps in `T2-PIN.md` |
| 2 | Local override re-wraps `qidi-studio` via `appimageTools.wrapAppImage`: adds `libsoup_3`/`libpng`/`glib-networking` to its FHS env, pins `SSL_CERT_FILE`/`SSL_CERT_DIR` at nixpkgs `cacert`, and points `GIO_EXTRA_MODULES` at glib-networking | `modules/home-manager/apps/3d-printing.nix` | nixpkgs `pkgs/by-name/qi/qidi-studio/package.nix` only lists `webkitgtk_4_1` in `extraPkgs`; the AppImage bundles just its ffmpeg libs, so webkitgtk's runtime deps (`libsoup_3`, `libpng`) never reach the FHS env and the app dies with `libsoup-3.0.so.0: cannot open shared object file`. The env also lacks the Fedora CA path (`/etc/pki/tls/certs/ca-bundle.crt`) the app probes (certificate-store nag) and glib-networking's GIO TLS backend, so every web view reports "TLS support not available". The sibling package `qidi-slicer-bin` already adds `libsoup_3`/`libpng` | upstream `qidi-studio` lists `libsoup_3`/`libpng` in `extraPkgs` (like `qidi-slicer-bin`) **and** the CA + GIO-TLS gaps are addressed; then use `pkgs.qidi-studio` directly and delete the override |
| 3 | Local binary patch of qidi-studio's webview User-Agent (`modules/scripts/patch-qidi-studio-ua.py`) to inject the Safari `Version/… Safari/…` tokens | `modules/home-manager/apps/3d-printing.nix` (`postExtract`) | `QIDITECH/QIDIStudio#244` — the non-Windows branch of `src/slic3r/GUI/Widgets/WebView.cpp` hardcodes a UA with no browser token, so the login / online-model page's UA sniffing can't set the `X-DeviceType` header and `api.qidimaker.com` replies `{"code":2010,"message":"X-DeviceType missing in request header"}`. Windows is unaffected (its UA has `Chrome/… Safari/…`). The token must be Safari, not Chrome: the webview is WebKitGTK, and the qidimaker SPA takes Chrome-only code paths it can't run, rendering the pages blank | upstream appends a standard browser token to the non-Windows UA (both in `WebView()` and `RecreateAll()`); then drop `postExtract`/the patch script and `contents`, reverting to `pkgs.appimageTools.wrapType2` |
| 4 | Store-measurement timeout in nixdatifier's `diskusage` helper raised from 120s to 300s (package patch via `overrideAttrs`) | `modules/home-manager/apps/nixdatifier.nix` (`patchedPackage`, `# TODO-remove:`) | `Muddyblack/nixdatifier`: `package/contents/tools/sh/diskusage` hardcodes `timeout --kill-after=5s 120s` around `nix-store --gc --print-dead`, and that scan alone takes ~119.5s on this store (326k paths, ~244k dead) — the probe is killed at random, so the Tools storage card stays empty while the free-space number (a cheap `df` read) still shows. Not yet reported upstream | upstream raises the cap or makes it configurable; then delete `patchedPackage` and keep the default package |
| 5 | Window outline recoloured to blend with the panel background (same `overrideAttrs` patch as #4) | `modules/home-manager/apps/nixdatifier.nix` (`patchedPackage`, `# TODO-remove:`) | `Muddyblack/nixdatifier`: the root panel `Rectangle` in `FullView.qml` hardcodes `border.color: UI.Theme.wash(fullView.accentColor, .18)` — a 1px outline of the accent colour at 18% opacity. With the dark palette accent (`#007bd3`) that reads as a faint blue frame around the standalone window, and no setting controls it. The patch repaints it with the panel background colour (visually identical to removing it with an opaque background) | upstream makes the border colour/width configurable or drops it; then delete this `substituteInPlace` |
| 6 | Xodus Nexus launcher packaged from its pinned GitHub AppImage (`fetchurl` + `appimageTools.wrapType2`) | `modules/home-manager/apps/xodus-nexus.nix` (`# TODO-remove:`) | not in nixpkgs and upstream `domsvoboda/xodus-nexus` publishes no `flake.nix` or Nix expression — only the AppImage and an `install.sh`. Upstream `xodus-gaming/xodus` is an unpackaged Rust CLI/service with no releases, and Nexus installs its own patched backend at runtime anyway | `pkgs.xodus-nexus` (or equivalent) lands in nixpkgs, or upstream publishes a flake/Nix package; then drop the pin and use the package/flake input |
| 8 | LearnHarness packaged from its pinned GitHub AppImage (`fetchurl` + `appimageTools.wrapType2`, GOD-KILLER only) | `modules/home-manager/apps/learnharness.nix` (`# TODO-remove:`) | not in nixpkgs (search.nixos.org unstable has no `learnharness`, checked 2026-11-03), and `amosblomqvist/learnharness` ships no `flake.nix` or Nix expression. The AppImage cannot self-update from the store; bump `version` + `hash` in the module | `pkgs.learnharness` lands in nixpkgs, or upstream publishes a flake/Nix package; then drop the pin and use the package/flake input |
| 9 | Native Hyprland capture helper (`t3-hyprland-snap-shot`) built from the `t3code` source with `rustPlatform.buildRustPackage` and installed into `t3code-unwrapped` via `overrideAttrs` `postInstall` (GOD-KILLER only; REDRUM's server package is untouched). Overriding the unwrapped package makes nix rebuild the Electron app locally | `modules/home-manager/ai-tools/t3code.nix` (`# TODO-remove:`); global bind in `modules/home-manager/desktop/hyprland.nix` | nixpkgs `pkgs/by-name/t3/t3code` (0.1.0, rev `3ec6363`) builds the Electron app but not the native capture helpers (`native/hyprland-snap-shot`, `native/kde-snap-shot`; only `native/browser-secret` and the resource monitor are packaged), so the unpackaged app reports "The Hyprland capture helper is missing from this build" when "Allow snapshots" runs setup. The app looks for the bundle at `<libexec/t3code>/native/hyprland-snap-shot/target/release/t3-hyprland-snap-shot` and lstat-rejects symlinks. The KDE helper is not packaged here (GOD-KILLER runs Hyprland) | nixpkgs `t3code` (or `t3code-unwrapped`) installs the Hyprland (and KDE) capture helper at that path; then drop `hyprlandCaptureHelper`/`t3codeWithCapture` and the `package` override, and verify "Allow snapshots" still works. The `CTRL + SHIFT + 2` global bind stays (it is config, not a workaround) |
| 10 | `opencode` taken from the previous nixpkgs (`inputs.nixpkgs-opencode`, rev `3ec636362e18`) instead of the main `nixpkgs` | `flake.nix` (input), `modules/home-manager/terminal/opencode.nix` (`# TODO-remove:`) | nixpkgs `1d06008` (observed 2026-11-05): the fixed-output derivation `opencode-node_modules-2.2.5` has a stale hash (specified `sha256-xfOVcw1+…`, got `sha256-prx9dX7k…`), so `pkgs.opencode` does not build | `nix build nixpkgs#opencode` succeeds on nixos-unstable; then use `pkgs.opencode` and delete the input |
| 11 | Stylix `rofi` target disabled for every home-manager user (loses nothing today: no module here enables rofi) | `modules/theme/stylix.nix` (`# TODO-remove:`) | `nix-community/stylix` `modules/rofi/hm.nix` still sets the renamed `programs.rofi.font` (home-manager now wants `programs.rofi.settings.font`), so every eval warns | Stylix sets `programs.rofi.settings.font`; then delete the `home-manager.sharedModules` line (rofi only needs the target back if it is ever enabled) |
| 12 | `programs.opencode.tui` forced empty and the Stylix theme selected through `programs.opencode.cli.theme = "stylix"` instead | `modules/home-manager/terminal/opencode.nix` (`# TODO-remove:`) | `nix-community/stylix` `modules/opencode/hm.nix` still writes `programs.opencode.tui.theme`, which OpenCode 2 ignores and home-manager warns about; the theme file itself (`programs.opencode.themes.stylix`) is still generated by Stylix | Stylix writes the theme name to `programs.opencode.cli`; then drop `tui = lib.mkForce { }` and `cli.theme` (and the `lib` argument) |
| 13 | `services.avahi` set directly (`settings.publish`: publishing and user-service publishing on, addresses published) with tether's `wifi.enable` left off; `wifi.openFirewall` still used | `modules/system/tether.nix` (`# TODO-remove:`) | `zackb/tether` `nix/module.nix` (`wifi.enable` block) still sets the obsolete `services.avahi.publish.enable` / `publish.userServices`, so any host enabling it warns | tether sets `services.avahi.settings.publish.*`; then set `wifi.enable = true` and delete the `services.avahi` block |

## Scheduled threads

Recurring T3 threads (upstream-fix registry polling, evaluation warnings per host, and a
per-machine "merged but not switched yet" notice) share a deterministic pre-step,
`docs/schedules/bin/schedule-precheck`, so a model only runs when something changed. Findings
become GitHub issues and `auto/<slug>` worker branches with PRs; nothing pulls or writes to
`~/.nixos`. Prompts, the issue-permission requirement and the REDRUM steps are in
[`docs/schedules/README.md`](docs/schedules/README.md).

## Scripts

- `rebuild.sh` — the daily-driver workflow. Streams the rebuild live with
  syntax highlighting (`bat`), shows only the errors on failure (logs kept in
  `.log/nixos-<action>.log`), and rebuilds locally or remotely
  (`--target-host --elevate sudo`). It works on whichever checkout it lives in
  (a T3 worktree or `~/.nixos`). With no arguments it is interactive: pick a host,
  review the diff, build, commit, then **switch** on `master` or **test** on any
  other branch, and push the current branch. The same steps are
  non-interactive stages so an AI agent can drive them (see
  [Change workflow](#change-workflow)):

  | Stage | Does | Privileges |
  | --- | --- | --- |
  | `check [HOST...]` | script syntax, tracked secrets/firmware, whitespace, registry sync, eval of each host | none |
  | `eval HOST` | evaluate only (prints the drvPath) | none |
  | `build HOST` | build + closure diff against the running system | none |
  | `test HOST [--target USER@IP]` | activate without a boot entry/generation | sudo (GUI askpass) |
  | `dry HOST [--target USER@IP]` | dry-activate: what a switch would restart | sudo |
  | `revert` | re-activate the recorded generation after a `test` | sudo |
  | `switch HOST [-m MSG] [--target USER@IP]` | `master` only: fetch and fast-forward to `origin/master`, commit a dirty tree with MSG, then switch | sudo |
  | `push` | push the current branch (never forced; `master` only from a terminal) | git credentials |
  | `generations [--target USER@IP]` | each generation with the commit/PR it was built from | none |
- `start.sh` — run from Hyprland on login: sets up the SSH agent with a GUI
  passphrase prompt. It no longer pulls the config: git is managed through T3
  threads and PRs, and `./rebuild.sh switch` fast-forwards `master` itself
  (see [How start.sh works](#how-startsh-works) below).
- `modules/scripts/config-sync.sh` — a manual, rarely needed config pull: verifies GitHub
  SSH auth and does the stash/pull/stash-pop against `~/.nixos`. Available from
  any terminal as the `config-sync` zsh alias (`bash
  ${../../scripts/config-sync.sh}`), so it works outside of login — e.g. midway
  through a session or SSH'd into REDRUM (needs the SSH key loaded in an agent;
  `start.sh` does this on login). Logs to `~/.nixos/.log/config-sync.log`.
- `modules/scripts/focus-window.sh` — focus an app by class/title or launch it.
- `modules/scripts/keybind-cheatsheet.sh` — render the xremap keymap as a
  cheatsheet (`Super+K X`).
- `modules/scripts/pip-move.sh` — move the floating picture-in-picture window
  around (`Super+Alt+HJKL`).
- `modules/scripts/parse_xremap.py` — parse the xremap config for reading/grepping.
- `modules/scripts/abt-browser-shim.js` — the Actual Budget Tweaks browser shim
  (upstream shim + the Stylix theme seed); stamped with the palette at build
  time, see [Actual Budget theming](#actual-budget-theming).

### How `start.sh` works

`start.sh` loads your SSH key into an agent every time you log in, without
blocking the desktop. Hyprland launches it on session start
(`hl.exec_cmd("bash $HOME/.nixos/start.sh")` in the `hyprland.start` hook in
`modules/home-manager/desktop/hyprland.nix`), and the final line
(`main "$@"`) runs it in the background.

The flow:

1. **Logging** — everything is written to `~/.nixos/.log/start.log`
   (`[INFO]/[WARN]/[ERROR]`), and key milestones are surfaced as desktop
   notifications via `notify-send`.
2. **Wait for desktop** — sleeps 2s so the session is fully up before anything
   tries to show a GUI.
3. **Key check** — bails out if `~/.ssh/id_ed25519` is missing (adjustable at the
   top of the script).
4. **GUI askpass** — sets `SSH_ASKPASS` to `openssh-askpass`'s GTK dialog
   (`/run/current-system/sw/libexec/gtk-ssh-askpass`) and exports
   `DISPLAY=:0` + `SSH_ASKPASS_REQUIRE=force` so every passphrase prompt is
   answered by a popup instead of a terminal. This is why the script only works
   from a session with a display.
5. **SSH agent** — starts `ssh-agent` if none is running and saves
   `SSH_AUTH_SOCK`/`SSH_AGENT_PID` to `~/.ssh/agent-info` (chmod 600) so
   unrelated processes can reuse the same agent.
6. **Load the key** — `ssh-add`s `~/.ssh/id_ed25519` through the GUI prompt
   (detached from any TTY with `setsid` so it never blocks on stdin).

There is no config sync step any more. `~/.nixos` stays a clean `master` that
only changes when you switch: `./rebuild.sh switch HOST` fetches and
fast-forwards it first. Branch work happens in T3 worktrees and reaches
`master` through merged PRs.

### `config-sync.sh` (the `config-sync` alias)

The GitHub check and the stash/pull/pop logic live in
`modules/scripts/config-sync.sh`. Nothing runs it automatically any more, and
you rarely need it: `./rebuild.sh switch` already fast-forwards `master`. It is
kept for pulling `~/.nixos` by hand without switching:

- **Anywhere in a terminal** — `config-sync` (zsh alias wired in
  `modules/home-manager/terminal/zsh.nix`, like `rebuild`).
- **SSH'd into REDRUM** — same `config-sync` command, as long as the SSH key is
  loaded in that agent (`ssh-add ~/.ssh/id_ed25519`).

The sync itself:

1. **Verify GitHub** — `ssh -T git@github.com` confirms the key is authorised
   (non-fatal — a failure only warns and continues).
2. **Stash** — any local uncommitted changes are stashed before pulling, so your
   edits are never lost or clobbered.
3. **Pull** — `git pull origin master` with a 30s timeout.
4. **Pop** — the stash is restored on success (you keep your local edits), and
   also if the pull failed, so nothing is stranded. If `~/.nixos` exists but
   isn't a repo, it warns instead of stomping on it.

If the pull succeeds you keep your local edits; on failure the stash is restored
and the script exits with status 1. The whole thing is safe to re-run anywhere —
`git pull` is idempotent — and the `.log/` files are gitignored.
Note that the askpass step in step 4 requires `openssh-askpass` to be installed
(e.g. via `modules/essentials/ssh.nix`).

### Tether pairing (per desktop host)

1. Rebuild so Tether (daemon, CLI, `tether-gtk`) is installed and the Bluetooth
   bits are live (`tether-btclass@hci0` + BlueZ experimental).
2. One-time Bluetooth system setup — prints only the commands this machine still
   needs (class-of-device + `bluetoothd --experimental`): `tether --bt-setup`.
   Run `tether bt setup` first if the CLI wants it; both are safe to re-run.
3. Pair over Bluetooth: pick the iPhone in `tether-gtk` (Devices → BLUETOOTH →
   "Pair over Bluetooth"), or `tether bt pair <addr>` (find it with
   `tether bt devices`). Confirm the code on both ends.
4. On the iPhone: Settings → Bluetooth → (i) next to this computer → enable
   **Show Message Notifications** and **Sync Contacts** (can take minutes to
   appear; re-open the page if blank).
5. Wi-Fi pairing (clipboard/file transfer/OTP via the iOS app): install
   "Tether - Linux Companion" from the App Store, open it, accept the pairing on
   both ends (`tether pending` / `tether accept <fingerprint>` from a terminal).

#### If pairing fails: Class of Device quirk (per host)

iOS only offers the "Show Message Notifications" / "Sync Contacts" toggles to a
peer whose Bluetooth Class of Device is **A/V Hands-Free** (`0x000408`, major 4 /
minor 8), and it evaluates that class at pairing/consent time. Two things to know:

- **The class never "sticks" on its own.** `bluetoothd` rewrites the adapter class
  from its own defaults whenever it (re)starts, clobbering both `main.conf`
  (`hardware.bluetooth.settings.General.Class = "0x000408"` in
  `modules/system/tether.nix`) and any `btmgmt` write. `tether --bt-status` may
  report `class=wrong` and `tether --bt-setup` a leftover "1 setup step" even
  though everything is configured. That is **cosmetic for an already-paired
  phone** — the granted session survives a class revert, so messages, contacts
  and notification mirroring keep working.
- **It only matters for a brand-new pair.** If the phone has never granted the
  permissions, re-apply the class *just before* pairing and keep the phone's
  Bluetooth off until then:

  ```bash
  sudo systemctl restart bluetooth
  sudo btmgmt class 4 8        # re-applies A/V Hands-Free until the next bluetoothd restart
  tether bt pair <addr>        # pair while the class is fresh
  ```

  Re-pairing an already-granted phone does **not** need this. If pairing still
  fails and MAP/PBAP are being refused, see the "1 setup step remaining"
  runbook in the Tether `BLUETOOTH.md` docs for the class + re-pair recovery.

Notes: notification mirroring (ANCS) requires iOS 19+; older iOS still gets
messages + contacts. The browser/mail extension opt-ins (`extensions` in
`modules/system/tether.nix`) are left off — enable `"firefox"`/`"chromium"` if
you want the OTP autofill native-messaging hosts.

## Installation

`GOD-KILLER` is also where this repo lives (`~/.nixos`), so it is a *self-hosting*
flake — the config in `modules/` is both the shipped system and the source of
this repository's files.

To deploy an existing machine:

```bash
# 1. Clone the flake (SSH)
git clone git@github.com:cqjro/nixos.git ~/.nixos
cd ~/.nixos

# 2. T2 hosts only (REDRUM, LittleNix), before their first build on this machine:
#    put the Apple brcm firmware in /var/lib/firmware-src/<HOST>/brcm (never in
#    the repo) and import it into the Nix store; see docs/firmware.md
nix run .#t2-firmware-import -- REDRUM

# 3. Rebuild any host from the repo (flake is self-contained, so this works
#    from any machine with Nix installed)
sudo nixos-rebuild switch --flake ".#GOD-KILLER"
#     replace GOD-KILLER with LittleNix or REDRUM as appropriate
```

For a fresh install from the live ISO, first bring up NixOS (installer →
`nixos-generate-config` → boot), then (for a T2 host, import its firmware as in
step 2 first):

```bash
# Prefer the standalone installer for correct hardware/partition setup, or:
nixos-install --flake ".#GOD-KILLER"
```

Notes:

- All hosts evaluate without `--impure`: the T2 firmware is a hash-pinned store
  path (`modules/system/t2-firmware.nix`), so clean clones and worktrees can
  evaluate every host; only *building* a T2 host needs its firmware imported on
  that machine. The firmware is proprietary — never commit, push or share it
  (see `docs/firmware.md`).
- Remote machines are configured for SSH keys over `git@github.com`, so
  `rebuild.sh` can deploy to any host and push the result back from anywhere.
- Every generation records the commit it was built from
  (`system.configurationRevision` plus a `git-<sha>` boot-menu label, from
  `modules/essentials/config-revision.nix`); `./rebuild.sh generations` lists
  them with the commit subject. See [Change workflow](#change-workflow).

## Change workflow

GitHub (`cqjro/nixos`) is the hub between machines, and every change is a
branch plus a PR. Only merged `master` becomes a recorded generation. The full
agent procedure is in `docs/agents/workflow.md`.

1. **Branch per item.** Each TODO item gets its own T3 thread in its own
   worktree on `todo/<slug>`, branched from `origin/master` (the `start-todo`
   skill sets this up and picks the model from the item's effort score). `~/.nixos`
   stays on a clean `master`.
2. **Verify.** The agent runs `./rebuild.sh check` and `./rebuild.sh build`
   for the affected hosts:
   - **GOD-KILLER** builds GOD-KILLER and REDRUM.
   - **REDRUM** builds only itself, and only *evaluates* GOD-KILLER (`./rebuild.sh eval GOD-KILLER`).
3. **Try it without recording it.** `./rebuild.sh test HOST` activates the
   branch build but writes no boot entry or generation. `./rebuild.sh revert`
   or a reboot undoes it. `./rebuild.sh dry HOST` only reports what would
   restart, which is the safer choice for network/SSH changes on headless REDRUM.
4. **Review.** Reviews are tiered, cheapest first:
   1. Deterministic checks, which are free.
   2. A Haiku convention reviewer.
   3. A Sonnet lockout reviewer, only for network, SSH, boot or tunnel changes.
   4. Opus, only as an escalation.

   Results go in the PR description (`.github/pull_request_template.md`).
5. **PR and merge.** When you ask, the agent pushes the branch and opens the PR
   (`gh pr create`). The PR is linked to the T3 thread. When you say "merge
   it", the agent runs `gh pr merge --squash --delete-branch`. Approving that
   permission card in T3 *is* the approval, because GitHub won't let you
   approve PRs made with your own token.
6. **Switch.** On each affected host, run
   `cd ~/.nixos && ./rebuild.sh switch HOST` (it fetches and fast-forwards master first). `switch`
   refuses to run off `master`.
7. **Trace a generation.** `./rebuild.sh generations` maps each generation to
   its commit and PR number. Older generations show the message from their
   old `HOST: <gen> … || message` commit.

Every agent reply ends with a **Path to close**: one ordered list of the
remaining steps, each tagged *Agent* or *You*, ending with the step that
closes the thread, plus any work delegated to other threads. Once nothing is
left but delegated work or waiting, the agent recommends settling (or snoozing)
the thread instead.

The post-switch "generation metadata" commit is gone. A commit now exists
before the switch, and the generation records it, so `master` only receives
reviewed merges or your own direct commits from the interactive flow.

## One-off tasks

Run the interactive rebuild (build → commit → switch on `master`, or test on a
branch → push):

```bash
./rebuild.sh
```

Or open a dev shell for the YouTube sync tooling:

```bash
nix develop .#youtube-sync
```

## REDRUM server setup

REDRUM exposes apps through **Cloudflare Tunnels** via `services.cloudflared` in
`modules/server/*.nix`. Each app gets its own tunnel, credentials file and
DNS record. The tunnel UUIDs are in the modules: they are identifiers, not
secrets. The tunnel *credentials* (`/var/lib/cloudflared/<app>.json`) are the
secret and are never in the repo. For a new app, provision the tunnel with the
steps below, commit its UUID in the module, and place the credentials file on
the server.

### 1. One-time Cloudflare auth (per machine)

```bash
ssh <server>
nix shell nixpkgs#cloudflared -c cloudflared tunnel login   # saves ~/.cloudflared/cert.pem
sudo cp ~/.cloudflared/cert.pem /var/lib/cloudflared/cert.pem   # make it readable by the service
```

### 2. Create a tunnel per app

```bash
sudo cloudflared tunnel create paperless   # prints a UUID, writes /var/lib/cloudflared/<uuid>.json
sudo cloudflared tunnel create glance
sudo cloudflared tunnel create beszel
sudo cloudflared tunnel create miniflux
sudo cloudflared tunnel create reactflux
# (linkwarden + actual-budget already have IDs, see their modules)
```

Copy each UUID into the matching `tunnels."<uuid>" = { credentialsFile = ...; }`
in `modules/server/{paperless,glance,beszel,miniflux,reactflux}.nix`.

### 3. Point each credentials file where Nix expects it

```bash
sudo mkdir -p /var/lib/cloudflared
sudo mv /var/lib/cloudflared/<uuid>.json /var/lib/cloudflared/paperless.json   # etc. per app
sudo chown root:root /var/lib/cloudflared/*.json && sudo chmod 600 /var/lib/cloudflared/*.json
```

(`credentialsFile` paths used by the modules: `paperless.json`, `glance.json`,
`beszel.json`, `linkwarden.json`, `actual-budget.json`, `miniflux.json`,
`reactflux.json`.)

### 4. Add DNS CNAME records (Cloudflare dashboard → DNS)

For each app hostname add a **CNAME** pointing at `<tunnel-uuid>.cfargotunnel.com`
(proxied). Hostnames used by this config:

| App | Hostname |
| --- | --- |
| Paperless | `docs.cqjro.ca` |
| Glance | `home.cqjro.ca` |
| Beszel | `status.cqjro.ca` |
| Linkwarden | `link.cqjro.ca` |
| Actual Budget | `budget.cqjro.ca` |
| Miniflux | `feed.cqjro.ca` |
| ReactFlux | `flux.cqjro.ca` |

The ingress rules in the Nix modules handle the traffic; DNS is the only thing
you manage in the dashboard (no `certificateFile` is used here).

### 5. Create app secrets (off the Nix store)

Each secret is typed at a hidden prompt (`read -rs`, works in zsh and bash) and written with
`install -m 600 -o <user>`, so it never lands in shell history, in `ps`, or in
a world-readable file. `printf` is a shell builtin, so the value is not on any
command line either.

```bash
sudo mkdir -p /var/lib/paperless
printf 'Paperless admin password: '; read -rs P; echo
printf '%s\n' "$P" | sudo install -m 600 -o paperless -g paperless /dev/stdin /var/lib/paperless/admin-password
unset P

sudo mkdir -p /var/lib/beszel
# KEY + optional TOKEN come from Beszel → Add System dialog
printf 'Beszel KEY: '; read -rs K; echo; printf 'Beszel TOKEN (optional): '; read -rs T; echo
printf 'KEY=%s\nTOKEN=%s\n' "$K" "$T" | sudo install -m 600 -o beszel-agent -g beszel-agent /dev/stdin /var/lib/beszel/agent.env
unset K T

sudo mkdir -p /var/lib/miniflux
# Miniflux first-run credentials (the module's adminCredentialsFile)
printf 'Miniflux admin password: '; read -rs P; echo
printf 'ADMIN_USERNAME=admin\nADMIN_PASSWORD=%s\n' "$P" | sudo install -m 600 -o miniflux -g miniflux /dev/stdin /var/lib/miniflux/admin.env
unset P
```

(Linkwarden additionally wants `/var/lib/linkwarden/nextauth-secret` and
`postgres-password`, and Actual Budget stores its data in `/var/lib/actual`.
ReactFlux needs no secrets — it's static files served by nginx; the browser
talks straight to the Miniflux API (CORS is enabled on Miniflux's side).)

### 6. Rebuild and log in once

```bash
./rebuild.sh                              # picks REDRUM, then restart cloudflared-tunnel-* if needed
ssh <server> systemctl restart cloudflared-tunnel-*.service
```

- Paperless → `https://docs.cqjro.ca` (superuser `admin` + the password from step 5).
- Beszel → `https://status.cqjro.ca` (create the admin account on first visit,
  then set the agent KEY from step 5 by editing `/var/lib/beszel/agent.env`).
- Glance → `https://home.cqjro.ca` (no login; styled by Stylix from the base16 palette).
- Miniflux → `https://feed.cqjro.ca` (log in with the `admin.env` credentials
  from step 5, then enable an API token under Settings → API Keys, and set a
  `BASE_URL`-matching "External base URL" if you change hosts).
- ReactFlux → `https://flux.cqjro.ca` (add the server as `https://feed.cqjro.ca`
  and paste the Miniflux API token from above; it stores config in your browser).

The feed-sync unit (`miniflux-rss-sync`) needs its own Miniflux API key (Settings
→ API Keys, description e.g. "rss-sync REDRUM"), stored where only the
`miniflux` user reads it. Run these one line at a time:

```bash
printf 'Miniflux API key: '; read -rs K; echo
printf '%s' "$K" | sudo install -m 600 -o miniflux -g miniflux /dev/stdin /var/lib/miniflux/api-token
unset K
sudo systemctl restart miniflux-rss-sync
```

### T3 Code on REDRUM

Agents can run on either machine because **each machine runs its own T3 server**
(an "environment"); clients connect to one or more of them over Tailscale. There
is no Cloudflare tunnel for T3.

| Environment | Server | Reached at |
| --- | --- | --- |
| GOD-KILLER | the desktop app's local backend (`127.0.0.1:3773`) | the app itself; for other devices publish it with `tailscale serve` (see [Reaching GOD-KILLER from other devices](#reaching-god-killer-from-other-devices)) |
| REDRUM | `t3code.service` (`modules/server/t3code.nix`, `127.0.0.1:8088`) | `https://redrum.<tailnet>.ts.net`, published by `t3code-tailscale-serve.service` |

Prerequisites: MagicDNS + HTTPS certificates enabled in the Tailscale admin
console. **Client and server versions must match:** the desktop app refuses an
older server ("This client requires a newer server"). REDRUM's pinned nixpkgs
only ships t3code 0.0.33, so `t3code.nix` takes the package from the main
`nixpkgs` input (the build GOD-KILLER runs; `# TODO-remove:` with the T2 pin) —
after a `nix flake update nixpkgs`, switch both machines. The same goes for the
`claude` CLI (`# TODO-remove:` with the pin): T3 only lists a Claude model when the
CLI meets that model's minimum version, and the pinned nixpkgs' 2.1.238 left REDRUM
with only the legacy model ("only legacy Fable 5 is available" in Settings). The server only drives the provider, it does not ship one, so the module
puts `claude`, `gh`, `git`, `bash` and `nix` on the unit's `PATH` (and `claude`/`gh`/`t3`
in the system profile), makes `gh` git's credential helper for the service only,
sets the service's git identity, adds the `t3code` user to `systemd-journal` (read
logs, no access to your home) and puts the sandbox tools on its `PATH`. The Claude
policy is the same `claude-code-policy` fragment as GOD-KILLER's (see "AI agents"
above). Log in once as the
`t3code` user after the switch — credentials land in `/var/lib/t3code`, never in
the store:

```bash
# run from t3code's home, not ~/.nixos: t3code cannot read /home/cairo (EACCES on .claude/settings.json)
sudo -u t3code -H sh -c 'cd ~ && claude'   # follow the login URL, paste the code, then /exit
sudo -u t3code -H sh -c 'cd ~ && gh auth login'   # GitHub.com -> HTTPS -> browser/device code (token lands in plain text in ~/.config/gh/hosts.yml, mode 0600; there is no keyring on a headless host)
sudo systemctl restart t3code
```

Then, on REDRUM, mint a pairing token for each device (default TTL 5 min):

```bash
sudo -u t3code -H t3 pair --label god-killer                # token for the desktop app
sudo -u t3code -H t3 pair --label iphone --ttl 15m \
  --scope orchestration:read --scope orchestration:operate  # phone: view + drive threads only
```

**The printed link points at the wrong host.** `t3 serve` binds to
`127.0.0.1:8088`, so the link and QR from `t3 pair` say `http://127.0.0.1:8088/…`,
which the client cannot reach (`Failed to fetch remote environment endpoint
http://127.0.0.1:8088/…`). Replace only that part with
`https://redrum.<tailnet>.ts.net` (no `:8088`, no `http`, and **no trailing dot** —
`tailscale status --json | jq -r .Self.DNSName` ends in one), keeping the path
and token as printed. `t3 pair --tailscale` is not an alternative: it would make
the `t3code` user run `tailscale serve` itself, without the rights to, and
compete with `t3code-tailscale-serve` for port 443.

Tokens are single-use and expire after `--ttl` (5 min default). "This credential
is invalid" means the token expired, was already tried (including the failed
`127.0.0.1` attempt) or was minted before a switch/restart — mint a new one and
use it once.

In the GOD-KILLER app, add REDRUM under Settings → Connections with the edited
link. The app stores saved connections in the system keyring; if it fails with
"Desktop secure storage is unavailable in this system context", the keyring is
locked — see [Keyring](#keyring-gnome-keyring) below. Threads on both machines
then show up in the same client. Pairing scopes include `terminal:operate` and
`filesystem:write` by default, so keep phone tokens narrow and revoke devices
from the connections list.

#### Working on either machine

The repo is one project on both servers: REDRUM has its own clone (owned by
`t3code` in `/var/lib/t3code`) and REDRUM builds were tested from it, so a
thread started on the REDRUM environment can edit, check, evaluate and build
REDRUM like one on GOD-KILLER (GOD-KILLER is eval-only there). T3 does not move
code between machines: GitHub is the hub, a thread stays on the server that runs
it, and a branch lives on one machine at a time (push, then fetch on the other).

Agents never switch a host by themselves. `claude-guard` refuses
`rebuild.sh switch|test|dry|revert|deploy` and `nixos-rebuild
switch|boot|test|dry-activate` in Auto and Full access; an agent that needs one
launches a Supervised child thread (its approval card is yours) or hands you the
command. From your phone:

- **GOD-KILLER:** open the GOD-KILLER environment's terminal in T3 (a real tty,
  so `sudo` asks for the password right there) and run `cd ~/.nixos &&
  ./rebuild.sh switch GOD-KILLER` as a plain command (tested 2026-11-06). A
  `systemd-run --user --wait` wrapper without `--pty` and `--working-directory`
  gives the command no tty (so it falls back to the desktop's GUI password
  dialog), no output and the wrong directory. A token with terminal scope is as
  powerful as your user: mint it only when needed and revoke it if the phone is
  lost.
- **REDRUM:** `ssh redrum`, then `./rebuild.sh switch REDRUM`.

#### Reaching GOD-KILLER from other devices

Nothing exposes the desktop backend by default, so a phone gets
`Remote environment endpoint https://god-killer.<tailnet>.ts.net/.well-known/t3/environment
timed out`. Publish it once on GOD-KILLER (MagicDNS + HTTPS certificates must be
enabled, as above):

```bash
sudo tailscale serve --bg --https=443 http://127.0.0.1:3773
tailscale serve status            # https://god-killer.<tailnet>.ts.net -> 127.0.0.1:3773
```

The mapping is saved in tailscaled's state and survives reboots and rebuilds. Then
open `https://god-killer.<tailnet>.ts.net/.well-known/t3/environment` on the phone
(Tailscale connected) — it should return JSON — and pair from the desktop app's
own pairing link/QR, not `t3 pair` (that targets a different server).

- **Port 443 is the right HTTPS port** (the app's default too). The backend port
  `3773` is whatever the app listens on (`ss -ltnp | grep electron`); if it ever
  changes, re-run the command with the new port.
- **The app's "Tailscale HTTPS" toggle silently does nothing** unless your user
  may change Tailscale settings: it runs the same `tailscale serve --bg
  --https=443 …` as your normal user and the rejection is not shown. Making
  yourself the operator (`sudo tailscale set --operator=$USER`) fixes the toggle
  but lets anything running as you (including agents) change Tailscale settings
  without a password. Prefer the one-off `sudo` command above; if you set the
  operator, undo it with `sudo tailscale set --operator=` — the saved mapping
  stays. Do not switch the toggle off afterwards: that runs `serve … off`, which
  needs the same rights (remove it deliberately with
  `sudo tailscale serve --https=443 off`).
- GOD-KILLER is only reachable while the desktop app is running and the machine
  is awake; REDRUM's service is always up.

#### Keyring (gnome-keyring)

Electron's secure storage (T3's saved connections, Xodus Nexus' sign-in) needs an
unlocked Secret Service. The `keyring` fragments in `modules/essentials/keyring.nix`
provide `gnome-keyring` and unlock the login keyring from the greetd PAM session;
the NixOS fragment is in the GOD-KILLER and LittleNix lists in `host.nix`, and the
home-manager one in GOD-KILLER's `machine.nix` imports. The unlock happens only at a **password** login
(not autologin/fingerprint), only after logging out and back in once, and only if
the keyring's password equals the login password. To unlock the running session
without logging out: `gnome-keyring-daemon --unlock`, then type the password.

## File access permissions (REDRUM)

Every service runs as its own dedicated system user (same pattern as `linkwarden`
and `actual-budget`). Users, homes and data dirs are provisioned by Nix
(`createHome = true`); secrets and agents' keys are created by hand and persist
across rebuilds.

| Path | Owner | Mode | Readable by |
| --- | --- | --- | --- |
| `/var/lib/paperless{,/media,/consume}` | `paperless:paperless` | 0700 | paperless-* services |
| `/var/lib/beszel-hub` (hub DB) | `beszel-hub:beszel-hub` | 0700 | beszel-hub |
| `/var/lib/beszel-agent` (agent DB) | `beszel-agent:beszel-agent` | 0700 | beszel-agent |
| `/var/lib/glance` (cache/DB) | `glance:glance` | 0700 | glance |
| `/var/lib/linkwarden` | `linkwarden:linkwarden` | 0700 | linkwarden |
| `/var/lib/actual` | `actual:actual` | 0700 | actual-budget |
| `/var/lib/miniflux` | `miniflux:miniflux` | 0700 | miniflux (data + `admin.env`) |
| `/var/lib/cloudflared/*.json` | `root:root` | 0600 | cloudflared-* (as root) |
| `/var/lib/paperless/admin-password` | `paperless:paperless` | 0600 | paperless (via credential) |
| `/var/lib/beszel/agent.env` | `beszel-agent:beszel-agent` | 0600 | beszel-agent (EnvironmentFile) |
| `/var/lib/glance/glance.env` | `glance:glance` | 0600 | glance (EnvironmentFile) |
| `/var/lib/miniflux/admin.env` | `miniflux:miniflux` | 0600 | miniflux (EnvironmentFile) |
| `/var/lib/miniflux/api-token` | `miniflux:miniflux` | 0600 | miniflux-rss-sync (`RSS_SYNC_TOKEN_FILE`) |
| `/var/lib/t3code` | `t3code:t3code` | 0700 | t3code (incl. `.claude/` login and `.config/gh/hosts.yml` token) |

Admin access is via `sudo` (`cairo` is in `wheel`) — keep the service dirs at
`0700` and owned by their own user so each app stays isolated from the others
(no shared `homelab` group needed).

- Verify identities: `id paperless glance beszel-hub beszel-agent miniflux`
- Inspect ownership: `sudo ls -l /var/lib`

Re-apply ownership after restoring a backup or copying files in as root:

```bash
sudo chown -R paperless:paperless   /var/lib/paperless
sudo chown -R beszel-hub:beszel-hub /var/lib/beszel-hub
sudo chown -R beszel-agent:beszel-agent /var/lib/beszel-agent
sudo chown -R glance:glance         /var/lib/glance
sudo chown -R miniflux:miniflux     /var/lib/miniflux
sudo chmod 600 /var/lib/paperless/admin-password /var/lib/beszel/agent.env /var/lib/glance/glance.env /var/lib/miniflux/admin.env
```

These users are not interactive logins, so operate as them with `sudo -u`:

```bash
sudo -u paperless -H bash                            # inspect the paperless home
sudo -u glance    -H glance --config /run/glance/glance.yaml --help
sudo -u beszel-hub -H beszel-hub --help
sudo -u beszel-agent -H true                          # sanity check
```

The initial data dirs are created with these owners by Nix on first activation;
after that ownership is stable across rebuilds — `chown -R` above is only needed
for restores or root-created files.

## Troubleshooting

### GitHub API rate limits

`nix flake update` may hit GitHub's API rate limit for unauthenticated requests. To fix this:

1. Create a read-only GitHub PAT (Fine-grained with `Contents: Read` for your referenced repos, or an empty-scope classic PAT).
2. Add it to `~/.config/nix/nix.conf` (outside of this repo):

   ```conf
   access-tokens = github.com=ghp_YOUR_TOKEN_HERE
   ```

3. Run `chmod 600 ~/.config/nix/nix.conf` and try `nix flake update` again.

This file is never tracked by git and is only used for API authentication, not for your SSH pushes.

### Troubleshooting tunnels

```bash
ssh <server>
sudo journalctl -u cloudflared-tunnel-<app> -f
sudo cloudflared tunnel list
curl -s http://127.0.0.1:8091 -H "Host: docs.cqjro.ca" | head    # app up on the origin?
```

---

## Disclaimer

This configuration is maintained with the assistance of AI tooling. Changes may
be generated, reviewed, or committed with AI help, and should be treated
accordingly before being applied to any machine.
