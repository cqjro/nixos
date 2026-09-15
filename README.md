# NixOS Config

My personal NixOS configuration, managed as a Git flake and spread across three
machines. Everything — desktop shell, terminal, apps, websites, even Discord and
Spotify — is themed from a single base16 palette via [Stylix](https://github.com/danth/stylix).

## Table of Contents

- [Machines](#machines)
- [Repository Layout](#repository-layout)
- [The Dendritic Pattern](#the-dendritic-pattern)
- [Theming](#theming)
- [Key Features](#key-features)
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
for details and the TODO for when it can be unpinned.

## Repository Layout

```
flake.nix              # Flake inputs (flake-parts + import-tree scaffolding)
rebuild.sh             # Interactive rebuild: selects a host, diffs, commits, pushes
start.sh               # Startup script run by Hyprland: loads SSH agent, pulls latest config

modules/
├── _archive/          # Retired / superseded modules (kept for reference)
├── essentials/        # System services: networking, dbus, bluetooth, audio, printing, users, nvidia...
├── hosts/             # Per-machine config:
│   ├── host.nix       #   Assembles all nixosConfigurations
│   ├── GOD-KILLER/    #   machine.nix / home.nix / hardware.nix / monitors.nix
│   ├── LittleNix/
│   └── REDRUM/        #   (incl. T2-PIN.md)
├── home-manager/      # User-level config
│   ├── apps/          #   calibre, millennium, mpv, nemo, spicetify, zen-browser, ...
│   ├── desktop/       #   hyprland, gtk, noctalia-shell, walker, ...
│   ├── keyboard/      #   xremap (powerful key remaps + app launching)
│   ├── languages/     #   latex, language toolchains
│   └── terminal/      #   zsh, ghostty, nvim, starship, yazi, btop, ...
├── scripts/           # Helper scripts (window focus, pip move, keybind cheatsheet)
├── server/            # REDRUM services: paperless, beszel, glance, homepage, actual-budget, linkwarden, cloudflared, tailscale, youtube
├── system/            # System-level config: games, minecraft, waydroid, ios-sideloading, flatpak, vpn...
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
  elevation, `base03` borders, `base05` text, `base0D` brand blue.
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
  Glance (feed dashboard, themed by Stylix), a Cloudflare-hosted homepage
  (with a Homelab tab listing every exposed app), and a systemd YouTube
  playlist-sync service backed by a `devShell` (`nix develop .#youtube-sync`).
- **System niceties** — Opt-in experimental features, auto-optimised store,
  Flatpak support, Minecraft + game launchers, Waydroid, iOS sideloading
  toolchain, `mtkclient`/`rockbox-utility` gadget firmware "doodads", VPN, and
  printing.

## Scripts

- `rebuild.sh` — the daily-driver workflow. Runs a `nix flake check`, rebuilds
  locally (or remotely via `--target-host --use-remote-sudo`), logs to `.log/`,
  then commits the result with generation metadata and pushes to `origin/master`.
- `start.sh` — run from Hyprland on login: sets up the SSH agent with GUI
  password prompting, verifies GitHub auth, and pulls the latest config.
- `modules/scripts/focus-window.sh` — focus an app by class/title or launch it.
- `modules/scripts/keybind-cheatsheet.sh` — render the xremap keymap as a
  cheatsheet (`Super+K X`).
- `modules/scripts/pip-move.sh` — move the floating picture-in-picture window
  around (`Super+Alt+HJKL`).
- `modules/scripts/parse_xremap.py` — parse the xremap config for reading/grepping.

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
# (linkwarden + actual-budget already have IDs, see their modules)
```

Copy each UUID into the matching `tunnels."<uuid>" = { credentialsFile = ...; }`
in `modules/server/{paperless,glance,beszel}.nix`.

### 3. Point each credentials file where Nix expects it

```bash
sudo mkdir -p /var/lib/cloudflared
sudo mv /var/lib/cloudflared/<uuid>.json /var/lib/cloudflared/paperless.json   # etc. per app
sudo chown root:root /var/lib/cloudflared/*.json && sudo chmod 600 /var/lib/cloudflared/*.json
```

(`credentialsFile` paths used by the modules: `paperless.json`, `glance.json`,
`beszel.json`, `linkwarden.json`, `actual-budget.json`.)

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
```

(Linkwarden additionally wants `/var/lib/linkwarden/nextauth-secret` and
`postgres-password`, and Actual Budget stores its data in `/var/lib/actual`.)

### 6. Rebuild and log in once

```bash
./rebuild.sh                              # picks REDRUM, then restart cloudflared-tunnel-* if needed
ssh <server> systemctl restart cloudflared-tunnel-*.service
```

- Paperless → `https://docs.cqjro.ca` (superuser `admin` + the password from step 5).
- Beszel → `https://status.cqjro.ca` (create the admin account on first visit,
  then set the agent KEY from step 5 by editing `/var/lib/beszel/agent.env`).
- Glance → `https://home.cqjro.ca` (no login; styled by Stylix from the base16 palette).

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
| `/var/lib/cloudflared/*.json` | `root:root` | 0600 | cloudflared-* (as root) |
| `/var/lib/paperless/admin-password` | `paperless:paperless` | 0600 | paperless (via credential) |
| `/var/lib/beszel/agent.env` | `beszel-agent:beszel-agent` | 0600 | beszel-agent (EnvironmentFile) |

Admin access is via `sudo` (`cairo` is in `wheel`) — keep the service dirs at
`0700` and owned by their own user so each app stays isolated from the others
(no shared `homelab` group needed).

- Verify identities: `id paperless glance beszel-hub beszel-agent`
- Inspect ownership: `sudo ls -l /var/lib`

Re-apply ownership after restoring a backup or copying files in as root:

```bash
sudo chown -R paperless:paperless   /var/lib/paperless
sudo chown -R beszel-hub:beszel-hub /var/lib/beszel-hub
sudo chown -R beszel-agent:beszel-agent /var/lib/beszel-agent
sudo chown -R glance:glance         /var/lib/glance
sudo chmod 600 /var/lib/paperless/admin-password /var/lib/beszel/agent.env
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