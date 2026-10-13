# NixOS Config

My personal NixOS configuration, managed as a Git flake and spread across three
machines. Everything — desktop shell, terminal, apps, websites, even Discord and
Spotify — is themed from a single base16 palette via [Stylix](https://github.com/danth/stylix).

## Table of Contents

- [Machines](#machines)
- [Repository Layout](#repository-layout)
- [The Dendritic Pattern](#dendritic-pattern)
- [Nix User Repository (NUR)](#nix-user-repository-nur)
- [Theming](#theming)
- [Key Features](#key-features)
- [Pending upstream fixes](#pending-upstream-fixes)
- [Scripts](#scripts)
- [Installation](#installation)
- [Rebuilding](#rebuilding)

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
workarounds currently in the tree.

## Repository Layout

```
flake.nix              # Flake inputs (flake-parts + import-tree scaffolding)
rebuild.sh             # Interactive rebuild: selects a host, diffs, commits, pushes
start.sh               # Startup script run by Hyprland: loads SSH agent, syncs config

modules/
├── _archive/          # Retired / superseded modules (kept for reference)
├── essentials/        # System services: networking, dbus, bluetooth, audio, printing, users, nvidia, nur...
├── hosts/             # Per-machine config:
│   ├── host.nix       #   Assembles all nixosConfigurations
│   ├── GOD-KILLER/    #   machine.nix / home.nix / hardware.nix / monitors.nix
│   ├── LittleNix/
│   └── REDRUM/        #   (incl. T2-PIN.md)
├── home-manager/      # User-level config
│   ├── apps/          #   3d-printing, calibre, millennium, mpv, nemo, photocraft, spicetify, zen-browser, ...
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

## Nix User Repository (NUR)

[NUR](https://github.com/nix-community/NUR) is a community registry of Nix
packages that have not (yet) landed in nixpkgs. It is wired in as the `nur`
flake input (`flake.nix`) with `inputs.nixpkgs.follows = "nixpkgs"`, so NUR
packages build against the same nixpkgs as the rest of the config.

The overlay is applied by `modules/essentials/nur.nix` — a thin dendritic
fragment that imports NUR's own NixOS module:

```nix
flake.modules.nixos.nur = {
  imports = [ inputs.nur.modules.nixos.default ];
};
```

Hosts opt in by adding `inputs.self.modules.nixos.nur` to their module list in
`modules/hosts/host.nix`; it is enabled on `GOD-KILLER` and `LittleNix`. Once
enabled, **any** NUR package is addressable as
`pkgs.nur.repos.<repo>.<package>` and can be used anywhere `pkgs` is available:

```nix
environment.systemPackages = [ pkgs.nur.repos.Skyb0rg007.photocraft ];
```

Browse packages at <https://nur.nix-community.org/> or search the
[nur-combined](https://github.com/nix-community/nur-combined) repository. NUR
packages are built from source and **not** reviewed by nixpkgs maintainers, so
read an expression before trusting it. NUR is only used for things that are
**not in nixpkgs yet** — on every nixpkgs bump, re-check NUR-installed apps and
switch to the official `pkgs.<name>` once the package lands there.

### Using NUR with Home Manager

These hosts set `home-manager.useGlobalPkgs = true`, so Home Manager shares the
system's `pkgs` — including the NUR overlay. `pkgs.nur...` therefore works in
home-manager modules with **no extra setup**, whether at the system level or in
a user fragment:

```nix
flake.modules.homeManager."some-app" = { pkgs, ... }: {
  home.packages = [ pkgs.nur.repos.Skyb0rg007.photocraft ];
};
```

A real example is `modules/home-manager/apps/photocraft.nix`.

If you ever move a machine to **standalone** Home Manager (or set
`useGlobalPkgs = false`), NUR's overlay must be applied to that `pkgs` directly
by importing its Home Manager module:

```nix
modules = [ inputs.nur.modules.homeManager.default ];
# ...
home.packages = [ pkgs.nur.repos.Skyb0rg007.photocraft ];
```

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
  **Vesktop** (nixcord's `vesktop` client + Vencord), since the standalone
  Discord package is currently disabled — see
  [Pending upstream fixes](#pending-upstream-fixes).
- **Spotify** — spicetify with a generated `color.ini` (same mapping) instead of
  a pre-baked theme, so it always matches.
- **Steam** — the **Millennium** client patch with the same palette mapping;
  toggled globally via `manifest.enableMillennium` / `manifest.enableSpicetify`
  (`modules/system/manifest.nix`).
- **OpenRGB** — systemd service for motherboard/mouse lighting.

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
  (self-hosted finance), Linkwarden (bookmarks), Beszel (server monitoring),
  Glance (feed dashboard, themed by Stylix), Miniflux (RSS reader) with
  ReactFlux (a Miniflux web client), a Cloudflare-hosted homepage
  (with a Homelab tab listing every exposed app), and a systemd YouTube
  playlist-sync service backed by a `devShell` (`nix develop .#youtube-sync`).
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
  terminal reader both consume it, so the same sources appear everywhere.
- **PhotoCraft** — an open-source, pure-Rust Photoshop alternative (layers,
  masks, adjustment layers, real PSD files), installed on the desktop hosts
  from NUR (`nur.repos.Skyb0rg007.photocraft`) via
  `modules/home-manager/apps/photocraft.nix`. See
  [Nix User Repository (NUR)](#nix-user-repository-nur) for the NUR workflow.
- **3D printing** — a slicer + modelling toolchain on the desktop hosts
  (GOD-KILLER, LittleNix): **QIDI Studio** as the slicer for QIDI printers
  (a Bambu Studio / PrusaSlicer fork), plus **FreeCAD** and **SolveSpace** for
  parametric CAD, **OpenSCAD** for script-driven solids and **Blender** for mesh
  work — installed via `modules/home-manager/apps/3d-printing.nix`. All are from
  nixpkgs; QIDI Studio is locally re-wrapped to fill gaps in its FHS env
  (`libsoup_3`/`libpng`, the CA bundle, and the GIO TLS backend) until the
  upstream package addresses them (see
  [Pending upstream fixes](#pending-upstream-fixes) row 4).

## Pending upstream fixes

Workarounds currently in the tree because of bugs or gaps **upstream**. Each
entry is a deliberate, temporary reduction in scope — re-check it whenever a
rebuild conversation starts, and drop the workaround once the upstream fix
lands. Keep this list in sync with the "Pending upstream fixes" section of
`AGENTS.md`, and add a row here in the same commit that introduces a new
workaround.

| # | Workaround | Where | Blocked on | Re-enable when |
| --- | --- | --- | --- | --- |
| 1 | Discord package install disabled (`programs.nixcord.discord.enable = false`); Vesktop is used instead | `modules/home-manager/apps/discord/nixcord.nix:9` | `kaylorben/nixcord` — `pkgs/discord/default.nix` does `basePackage.override { inherit source; … }`, but nixpkgs moved `discord` to `pkgs/by-name/di/discord/package.nix` where `source` comes from `./metadata.nix` and is no longer a function argument. Since `nixcord.inputs.nixpkgs.follows = "nixpkgs"`, every nixpkgs bump breaks evaluation with `function 'anonymous lambda' called with unexpected argument 'source'` | nixcord guards `source` the way it already guards `useFHSEnv` (`basePackageSupportsFHSEnv`) — then set `discord.enable = true` |
| 2 | REDRUM built from a pinned nixpkgs (`cac0c1ef`, kernel 6.18.46) instead of `nixpkgs/nixos-unstable` | `flake.nix:18`, `modules/hosts/host.nix:91`, `modules/hosts/REDRUM/T2-PIN.md` | `NixOS/nixos-hardware#2027` — `linux_6_18 >= 6.18.47` rejects the `facf1c7` t2linux patchset | the issue is resolved (or the pin is otherwise obsolete); full removal steps in `T2-PIN.md` |
| 3 | Insecure pnpm version allowed on GOD-KILLER (`nixpkgs.config.permittedInsecurePackages`) | `modules/hosts/GOD-KILLER/machine.nix:3` | a pnpm release in nixpkgs that is no longer flagged insecure (reactflux needs pnpm ≥ 10.29.2) | nixpkgs ships a non-insecure pnpm satisfying reactflux's `engines`, then drop the list |
| 4 | Local `appimageTools.wrapType2` override re-wraps qidi-studio: adds `libsoup_3`/`libpng`/`glib-networking` to its FHS env, pins `SSL_CERT_FILE`/`SSL_CERT_DIR` at nixpkgs `cacert`, and points `GIO_EXTRA_MODULES` at glib-networking | `modules/home-manager/apps/3d-printing.nix` | nixpkgs `pkgs/by-name/qi/qidi-studio/package.nix` only lists `webkitgtk_4_1` in `extraPkgs`; the AppImage bundles just its ffmpeg libs, so webkitgtk's runtime deps (`libsoup_3`, `libpng`) never reach the FHS env and the app dies with `libsoup-3.0.so.0: cannot open shared object file`. The env also lacks the Fedora CA path (`/etc/pki/tls/certs/ca-bundle.crt`) the app probes (certificate-store nag) and glib-networking's GIO TLS backend, so every web view reports "TLS support not available". The sibling package `qidi-slicer-bin` already adds `libsoup_3`/`libpng` | upstream `qidi-studio` lists `libsoup_3`/`libpng` in `extraPkgs` (like `qidi-slicer-bin`) **and** the CA + GIO-TLS gaps are addressed; then use `pkgs.qidi-studio` directly and delete the override |

Nothing is lost from #1 in practice: Vesktop is a separate nixcord client
(`finalPackages.vesktop`), so Vencord, the ~17 KB Stylix `quickCss` theme, the
`config.plugins` block and the Vesktop settings are all still applied — only
the separate `discord` binary is given up. The theme, YouTube adblock and
`discordBranch = "canary"` all live in `~/.config/vesktop/`.

## Scripts

- `rebuild.sh` — the daily-driver workflow. Streams the rebuild live with
  syntax highlighting (`bat`), shows only the errors on failure (log kept at
  `.log/nixos-switch.log`), rebuilds locally or remotely
  (`--target-host --use-remote-sudo`), commits with generation metadata, and
  pushes to `origin/master`.
- `start.sh` — run from Hyprland on login: sets up the SSH agent with a GUI
  passphrase prompt and pulls the latest config, delegating the sync itself to
  `config-sync.sh` (see [How start.sh works](#how-startsh-works) below).
- `modules/scripts/config-sync.sh` — the config sync on its own: verifies GitHub
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

### How `start.sh` works

`start.sh` re-syncs the NixOS config from GitHub every time you log in, without
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
7. **Sync the config** — runs `modules/scripts/config-sync.sh`, which verifies
   GitHub auth (`ssh -T git@github.com`, non-fatal) and then does the
   stash/pull/stash-pop described below. Its own log lives at
   `~/.nixos/.log/config-sync.log`.

### `config-sync.sh` (the `config-sync` alias)

The GitHub check and the stash/pull/pop logic live in
`modules/scripts/config-sync.sh` so the sync can be re-run on demand — `start.sh`
just executes it after loading the SSH key. Whenever you need to pull the latest
config outside of a login:

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

# 2. Rebuild any host from the repo (flake is self-contained, so this works
#    from any machine with Nix installed)
sudo nixos-rebuild switch --flake ".#GOD-KILLER" --impure
#     replace GOD-KILLER with LittleNix or REDRUM as appropriate
```

For a fresh install from the live ISO, first bring up NixOS (installer →
`nixos-generate-config` → boot), then:

```bash
# Prefer the standalone installer for correct hardware/partition setup, or:
nixos-install --flake ".#GOD-KILLER" --impure
```

Notes:

- `--impure` is required because the flake reads files from `~/.nixos` that
  aren't declared as inputs (e.g. the REDRUM/littleNix `brcm-firmware` bundle).
- Remote machines are configured for SSH keys over `git@github.com`, so
  `rebuild.sh` can deploy to any host and push the result back from anywhere.
- Monitoring and applying per-host generation metadata
  (`nixos-rebuild list-generations`) is built into `rebuild.sh`.

## One-off tasks

Run the interactive rebuild with test-then-switch and a full history:

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
DNS record. The tunnel UUID + credentials are *not* in the repo; provision them
once per app with the steps below, then fill the placeholder tunnel IDs and
secret files on the server.

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

```bash
sudo mkdir -p /var/lib/paperless
sudo sh -c 'echo "change-me-admin-password" > /var/lib/paperless/admin-password'
sudo chown paperless:paperless /var/lib/paperless/admin-password

sudo mkdir -p /var/lib/beszel
# KEY + optional TOKEN come from Beszel → Add System dialog
sudo sh -c 'printf "KEY=<public key>\nTOKEN=<universal token>\n" > /var/lib/beszel/agent.env'
sudo chown beszel-agent:beszel-agent /var/lib/beszel/agent.env

sudo mkdir -p /var/lib/miniflux
# Miniflux first-run credentials (the module's adminCredentialsFile)
sudo sh -c 'printf "ADMIN_USERNAME=admin\nADMIN_PASSWORD=<change-me>\n" > /var/lib/miniflux/admin.env'
sudo chown miniflux:miniflux /var/lib/miniflux/admin.env
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

## Troubleshooting tunnels

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