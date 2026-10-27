# AGENTS.md

Guidance for AI agents working on this repository. Read this before touching the
config; the [README.md](./README.md) has the human-oriented overview — keep the
two in sync (see [Documentation Maintenance](#documentation-maintenance)).

## Project at a glance

Personal NixOS flake (`flake-parts` + `import-tree`) that configures three
machines (`GOD-KILLER`, `LittleNix`, `REDRUM`) from a pool of small, self-contained
module fragments, all themed from one base16 palette via Stylix.

## Quick commands

```bash
nix flake check --impure          # verify the flake evaluates (manual, not part of rebuild.sh)
bash -n rebuild.sh start.sh modules/scripts/*.sh   # syntax-check scripts
./rebuild.sh                      # interactive rebuild: pick host -> diff -> commit -> push
config-sync                       # zsh alias -> modules/scripts/config-sync.sh (stash/pull/pop ~/.nixos)
nix develop .#youtube-sync        # devshell for the youtube-sync helper
sudo nixos-rebuild switch --flake ".#GOD-KILLER" --impure   # rebuild a specific host
nixos-rebuild list-generations    # generation metadata (used in commit messages)
```

- `--impure` is **required** (`rebuild.sh` passes it) because the flake reads
  files not declared as inputs, such as the `brcm-firmware` bundles in
  `modules/hosts/{LittleNix,REDRUM}`.
- No formatter/linter is enforced (alejandra is commented out in `rebuild.sh`).
  Match the existing style: **tab indentation**, Nix strings with double quotes,
  existing naming conventions.
- There are no automated tests; verification is `nix flake check` + a successful
  rebuild.

## Repository structure

```
flake.nix          # inputs + flake-parts/import-tree scaffolding (the "dendritic" core)
rebuild.sh         # interactive rebuild + auto-commit + push
start.sh           # login script: ssh-agent + config auto-pull
modules/
  essentials/      # shared system services (networking, users, audio, nvidia, …)
  hosts/           # host.nix (assembles nixosConfigurations) + one dir per machine
  home-manager/    # user config: apps/, desktop/, keyboard/, languages/, terminal/
  scripts/         # helper shell/python scripts
  server/          # REDRUM services (actual-budget, linkwarden, tailscale, …)
  system/          # games, minecraft, waydroid, ios-sideloading, tether, vpn, manifest, rss-sources, …
  theme/           # stylix scheme + openrgb + webstyling/ + discord-theme
  _archive/        # retired modules — prefer archiving here over deleting
```

Full documentation lives in the README (`Machines`, `Repository Layout`,
`Key Features`, etc.) — do not duplicate that detail here.

## The module pattern (how to add a feature)

Every `.nix` file under `modules/` is auto-imported by `import-tree`. A file
declares fragments under the flake-parts namespace:

```nix
{ inputs, ... }:
{
  flake.modules.nixos."my-feature" = { pkgs, ... }: { ... };       # NixOS side
  flake.modules.homeManager."my-feature" = { config, lib, ... }: { ... };  # user side
}
```

Hosts then opt in **explicitly**:

- System level: add `inputs.self.modules.nixos."my-feature"` to the host's module
  list in `modules/hosts/host.nix`.
- User level: add `input-name` (`my-feature`) to the `imports` list inside each
  host's `machine.nix` (`with inputs.self.modules.homeManager`).

Other conventions:

- Fragment names are exact strings and often contain hyphens — quote them
  (`inputs.self.modules.nixos."GOD-KILLER-hardware"`).
- Per-host overrides for a shared module are implemented as **module options**
  consumed elsewhere. Example: `hyprland.monitors` / `hyprland.bindel` are
  defined in `home-manager/desktop/hyprland.nix` and set per host in
  `hosts/<HOST>/home.nix` / `monitors.nix`.
- Feature toggles live in `system/manifest.nix`
  (`manifest.enableMillennium`, `manifest.enableSpicetify`) and gate
  `mkIf` blocks in consumer modules (see `home-manager/apps/spicetify.nix`).
- Shared **data** fragments also live NixOS-side and are consumed user-side via
  `osConfig`. Example: `rss-sources.feeds` (in `modules/system/rss-sources.nix`)
  feeds the glance rss widget through `config.rss-sources.feeds` and
  `nom` via `osConfig.rss-sources.feeds`.
- Theming is always derived from Stylix colors (`config.lib.stylix.colors.baseXX`)
  or `config.stylix.*` — never hardcode new colors in modules, extend the scheme
  in `modules/theme/stylix.nix` instead.
- Prefer **relative paths** over absolute ones (e.g. `./firmware/brcm` in
  `LittleNix/machine.nix`). The latest commits moved paths to relative.
- Star imports from the fragment's `{ pkgs, ... }` arguments rather than
  introducing deps at the top level, matching surrounding files.

**NUR packages removed.** All Nix User Repository (NUR) inputs, modules, and NUR-sourced packages have been removed from this configuration. NUR packages can be removed at any time and may require finding new sources or packaging them differently.

### Creating a server module (REDRUM)

`modules/server/*.nix` each define an app on REDRUM, exposed through a
Cloudflare tunnel. Follow the existing modules (`linkwarden.nix`,
`actual-budget.nix`, `minsiflux.nix`) — each one **must**:

1. **Pick a free local port** (gres: glance 8081, homepage 8082, linkwarden 8083,
   miniflux 8084, reactflux 8085) and a `*.cqjro.ca` hostname. Bind the app to
   `127.0.0.1:<port>` (nginx's `defaultListen` when reverse-proxying static
   content), never `0.0.0.0`.

2. **Run as its own dedicated user**: `users.users.<app>` (`isSystemUser`,
   `group = "<app>"`, `home = "/var/lib/<app>"`, `createHome = true`) plus
   `users.groups.<app> = {}` — see `miniflux.nix`. If the nixpkgs module ships
   a `DynamicUser` service, pin it with
   `systemd.services.<svc>.serviceConfig = { DynamicUser = lib.mkForce false; User = "<app>"; Group = "<app>"; };`.

3. **Keep secrets off the Nix store**: write them once by hand under
   `/var/lib/<app>/` on REDRUM (e.g. miniflux `admin.env`), reference them via
   paths / `EnvironmentFile` in the module, and document the exact create
   commands in the README's "Create app secrets" step.

4. **Add the tunnel block**:
   `services.cloudflared.tunnels."<uuid>" = { credentialsFile = "/var/lib/cloudflared/<app>.json"; default = "http_status:404"; ingress = { "<host>.cqjro.ca" = "http://localhost:<port>"; }; };`
   Use a **placeholder UUID marked with a `# TODO:` comment** (real UUIDs are
   provisioned per-machine and never committed). Keep the shared
   `hostname → port` table in the README accurate, and list the app in the
   Homepage Homelab tab (`modules/server/homepage.nix` is a config fragment of
   its own) if it should show there.

5. **Wire and document**: add `inputs.self.modules.nixos."<name>"` to the REDRUM
   module list in `modules/hosts/host.nix`, then update the README: the   feature bullet, the tunnel create/credential steps, the DNS CNAME table, the
   permissions table (`/var/lib/<app>` row) and the "log in once" notes.

6. **Static frontends** (e.g. ReactFlux, a pnpm/Vite SPA): package the build as a
   `pkgs.stdenv.mkDerivation` and serve the store path straight from nginx —
   no app user needed. For pnpm projects, follow `reactflux.nix`: an immutable
   fixed-output `pnpm install` must run **with network** (that's the only place
   the registry is touched), then the real build installs `--offline` against a
   *copied* (writable) store **and** metadata cache. Neither `fetchPnpmDeps` nor
   `buildPnpmPackage` exist in the pinned nixpkgs on REDRUM — hand-roll both.
   `nix flake check` on REDRUM is not part of the loop; verify with
   `nix eval --impure '.#nixosConfigurations.REDRUM.config.system.build.toplevel.drvPath'`.

### Theming the Actual Budget Tweaks sidecar

`modules/server/actual-budget-tweaks.nix` wraps Actual Budget in the ABT sidecar
(a Node reverse proxy that injects ABT's UI tweaks into every browser). ABT
themes via a `--ctp-*` token map, so the sidecar is seeded with a palette
derived from the shared Stylix base16 scheme:

- The base16 → ABT token map is built **NixOS-side** (needs
  `config.lib.stylix.colors`), emitted as JSON, and stamped into
  `modules/scripts/abt-browser-shim.js` — the upstream shim plus a small seed
  appended. `pkgs.runCommand` overrides just `browser-shim.js` inside the
  sidecar store path (server.js serves it from the sidecar root).
- The seed writes a `user:stylix` palette into ABT's `local:user-themes` and
  selects it in `local:catppuccin-palette` **only when that key is unset**, so
  any theme chosen later in ABT's own Theme Customizer (incl. `Native`) wins.
  ABT's settings-sync copies both keys into the budget, so the choice persists.
- `services.abt-sidecar.stylixTheme = false` (set in `modules/hosts/host.nix`)
  skips the override and leaves the stock shim/theme. Both branches are worth
  re-checking on ABT bumps: the shim mirrors upstream
  `docker/browser-shim.js` at the pinned rev and the token names come from
  `src/lib/design/palettes/*.ts` — if either changes, update
  `modules/scripts/abt-browser-shim.js` / the `stylixKeys` map.

### Archiving a module (required steps)

Never delete a module outright; move it to `modules/_archive/` instead. Every
archived module **must**:

1. Carry a `# Archived from modules/<dir>/<file>.nix` header comment recording
   where it used to live.
2. Document (in additional comments) where it would sit if reintegrated
   (`modules/<dir>/<file>.nix`), and a step-by-step "To reintegrate" block:
   the `git mv` command, which hosts/fragments to re-add and where
   (e.g. `inputs.self.modules.nixos."<name>"` in `modules/hosts/host.nix`),
   and the rebuild command.
3. Remove any references to the module from active config in the same commit —
   detach dormant fragments from `modules/hosts/host.nix` module lists, delete
   stale commented-out imports, and drop tied flake inputs: **comment the input
   out in `flake.nix` with a `# archived: …` note** (e.g. `# archived: flatpak
   module moved to modules/_archive/flatpak.nix`) instead of deleting it, and
   remove any `inputs.<name>.nixosModules.*` usage from `host.nix`. `flake.lock`
   will drop the commented inputs on the next lockfile update — that is expected.
4. Keep the fragment definition inside the archived file intact so it can be
   re-activated by simply moving the file back into place (import-tree still
   picks it up in `_archive/`).
5. Reintegration is the reverse: re-add the module to the host's module list,
   **uncomment the flake input in `flake.nix`** (re-running
   `nix flake update <name>` or `nix flake lock` to restore it into
   `flake.lock`), re-add any `host.nix` input-module lines, then rebuild.

## Pending upstream fixes (follow-up registry)

Workarounds that exist **only** because of a bug or gap upstream. They are
deliberate, temporary reductions in scope — never treat one as intentional
design, and never "clean it up" without first confirming the upstream fix.

**Standing instruction: on every rebuild conversation, before doing anything
else, re-check each entry below for an upstream fix.** If one has landed, say
so explicitly, then remove the workaround and verify the host still builds. If
it has not, report the current status briefly and move on. Checking means
looking at the linked issue/PR (or the upstream commit log for the relevant
file), not assuming from the passage of time.

| # | Workaround | Where | Blocked on | Re-enable when |
| --- | --- | --- | --- | --- |
| 1 | `programs.nixcord.discord.enable = false` — standalone Discord package not installed; Vesktop is the client | `modules/home-manager/apps/discord/nixcord.nix:9` | `kaylorben/nixcord`: `pkgs/discord/default.nix` calls `basePackage.override { inherit source; … }`, but nixpkgs refactored `discord` into `pkgs/by-name/di/discord/package.nix` where `source` is read from `./metadata.nix` and is no longer a function argument. `nixcord.inputs.nixpkgs.follows = "nixpkgs"` (flake.nix:79), so any nixpkgs bump fails with `function 'anonymous lambda' called with unexpected argument 'source'` | nixcord guards `source` the way it already guards `useFHSEnv` (`basePackageSupportsFHSEnv`, `pkgs/discord/default.nix:53`). Then set `discord.enable = true` |
| 2 | REDRUM built from pinned nixpkgs `cac0c1ef` (kernel 6.18.46) instead of `nixpkgs/nixos-unstable` | `flake.nix:18`, `modules/hosts/host.nix:91`, `modules/hosts/REDRUM/T2-PIN.md` | `NixOS/nixos-hardware#2027` — `linux_6_18 >= 6.18.47` rejects the `facf1c7` t2linux patchset | issue resolved / pin obsolete; follow the numbered removal steps in `T2-PIN.md` |
| 3 | `nixpkgs.config.permittedInsecurePackages = [ "pnpm-10.29.2" ]` on GOD-KILLER | `modules/hosts/GOD-KILLER/machine.nix:3` | nixpkgs has no non-insecure pnpm ≥ 10.29.2 yet (reactflux's `engines` need it) | nixpkgs ships a non-insecure pnpm satisfying reactflux; then delete the list |
| 4 | local override re-wraps `qidi-studio` via `appimageTools.wrapAppImage`: `libsoup_3`/`libpng`/`glib-networking` added to its FHS env (`extraPkgs`), `SSL_CERT_FILE`/`SSL_CERT_DIR` pinned at nixpkgs `cacert`, and `GIO_EXTRA_MODULES` pointed at glib-networking | `modules/home-manager/apps/3d-printing.nix` | nixpkgs `pkgs/by-name/qi/qidi-studio/package.nix` only puts `webkitgtk_4_1` in `extraPkgs`; the AppImage bundles only its ffmpeg libs, so webkitgtk's runtime deps (`libsoup_3`, `libpng`) are absent from the FHS env and the app fails with `libsoup-3.0.so.0: cannot open shared object file`. The env also lacks the Fedora CA path (`/etc/pki/tls/certs/ca-bundle.crt`) the app probes ("use system SSL certificate … continue?" prompt) and glib-networking's GIO TLS backend, so web views report "TLS support not available" (GLib's dummy TLS backend; same fix as nixpkgs #528942 / QBZ). The sibling `qidi-slicer-bin` already adds `libsoup_3`/`libpng` | upstream `qidi-studio` lists `libsoup_3`/`libpng` in `extraPkgs` (like `qidi-slicer-bin`) **and** the CA + GIO-TLS gaps are addressed; then install `pkgs.qidi-studio` directly and delete the override |
| 5 | binary patch of `qidi-studio`'s webview User-Agent (via `modules/scripts/patch-qidi-studio-ua.py`, run from `postExtract` on a custom `contents`) to inject the Safari `Version/… Safari/…` tokens | `modules/home-manager/apps/3d-printing.nix`, `modules/scripts/patch-qidi-studio-ua.py` | `QIDITECH/QIDIStudio#244` — the non-Windows branch of `src/slic3r/GUI/Widgets/WebView.cpp` hardcodes a UA with no browser token, so the login / online-model pages' UA sniffing can't set the `X-DeviceType` header and `api.qidimaker.com` replies `{"code":2010,"message":"X-DeviceType missing in request header"}`. Windows is unaffected (its UA has `Chrome/… Safari/…`). The token must be Safari, not Chrome: the webview is WebKitGTK, and the qidimaker SPA takes Chrome-only code paths it can't run, rendering the pages blank | upstream appends a standard browser token to the non-Windows UA (in both `WebView()` and `RecreateAll()`); then drop `postExtract`, the patch script and `contents`, reverting to plain `appimageTools.wrapType2` |
| 6 | `diskusage` store-measure timeout raised 120s → 300s via `overrideAttrs` on the nixdatifier package (covers the window and the desktop CLI; `ui = false` keeps the stock cli package) | `modules/home-manager/apps/nixdatifier.nix` (`patchedPackage`, `# TODO-remove:`) | `Muddyblack/nixdatifier`: `package/contents/tools/sh/diskusage` hardcodes `timeout --kill-after=5s 120s` around `nix-store --gc --print-dead`, which takes ~119.5s on this store (326k paths, ~244k dead) — the probe is killed at random and the Tools storage card never fills in (free space still shows via `df`). Not yet reported upstream | upstream raises the cap or makes it configurable; then drop `patchedPackage` and use the default package |
| 7 | window outline recoloured to match the panel background: `substituteInPlace` on the installed `FullView.qml` turns the hardcoded `wash(accentColor, .18)` border into the background colour (same `overrideAttrs` block as #6) | `modules/home-manager/apps/nixdatifier.nix` (`patchedPackage`, `# TODO-remove:`) | `Muddyblack/nixdatifier`: the root panel `Rectangle` hardcodes `border.color: UI.Theme.wash(fullView.accentColor, .18)` — with the dark palette accent (`#007bd3`) it renders as a faint blue frame around the standalone window; no setting controls it | upstream makes the border configurable or drops it; then delete this `substituteInPlace` |
| 8 | Xodus Nexus launcher packaged from its pinned GitHub AppImage (`fetchurl` + `appimageTools.wrapType2`) | `modules/home-manager/apps/xodus-nexus.nix` (`# TODO-remove:`) | not in nixpkgs (`pkgs/by-name/xo` has no `xodus`), and `domsvoboda/xodus-nexus` ships no `flake.nix` or Nix expression. Upstream `xodus-gaming/xodus` is an unpackaged Rust CLI/service with no releases, and Nexus installs its own patched backend at runtime anyway | `pkgs.xodus-nexus` (or equivalent) lands in nixpkgs, or upstream publishes a flake/Nix package; then drop the pin and use the package/flake input |

Notes:

- #1 costs nothing in practice: Vesktop is a **separate** nixcord client
  (`finalPackages.vesktop`), so Vencord, the Stylix `quickCss` theme,
  `config.plugins` and the Vesktop settings are all still written to
  `~/.config/vesktop/`. Only the separate `discord` binary is gone. Because the
  crash is lazy, forcing `programs.nixcord` as a whole attrset still throws
  (it reaches `discord.package`); the *system build* is what must pass.
- A `# TODO-remove:` comment at the workaround site is required, and the same
  row must exist in the README's "Pending upstream fixes" table — update both
  in the commit that adds the workaround, and delete from both when removing it.
- Archive-to-`modules/_archive/` is for *retired* modules. A module disabled
  pending an upstream fix stays in place and gets a registry row instead.

## Gotchas

- **Waydroid Android userdata is `~/.local/share/waydroid`**, not
  `/var/lib/waydroid/userdata.img` (`waydroid.host_data_path`). Replacing the
  images or running `waydroid init -f` does not reset it. Stale data from an
  older Android release makes `zygote`/`system_server` crash-loop after an
  image bump — symptoms: Container RUNNING but IP `UNKNOWN`, `show-full-ui`
  stuck on `waydroidplatform`, and the kernel log repeating
  `process with updatable components 'zygote' exited 4 times before boot
  completed`. Stop the session, `rm -rf ~/.local/share/waydroid`, restart; the
  installer script now does this (`modules/scripts/waydroid-atv-install.sh`).
- **Waydroid is black on GOD-KILLER while the display is on NVIDIA** — confirmed
  2026-10-25, and it is not an image/prop bug. Waydroid's probe skips
  `nvidia`, so it renders on the AMD iGPU (`renderD129`), while Hyprland scans
  out DP-3/HDMI-A-1 from NVIDIA (`card1`); the AMD dmabufs are never presented
  and Hyprland logs no EGL/import error. A forced-Mesa `mpv` reproduces it
  (NVIDIA client visible, AMD client black). Don't chase ATV logcat. See
  `docs/waydroid/PLAN.md` → "Handoff — paused 2026-10-25" for the A/B evidence
  and the topology/upstream options.
- **Xodus Nexus is a pinned AppImage** (`modules/home-manager/apps/xodus-nexus.nix`,
  `GOD-KILLER` only). Nix packages only the launcher; its Xodus backend and
  Nexus runtime self-install from GitHub into the user data directory on first
  run (Settings → Xodus backend / Nexus runtime → Install). The launcher cannot
  self-update from its read-only store path — bump the module's `version` and
  `hash` instead. It needs an unlocked keyring, so the module also enables
  `gnome-keyring` and greetd PAM unlocking; the passkey "Continue in browser"
  fallback needs Google Chrome.
- **Secrets and firmware are gitignored** and must never be committed
  (`client_secret.json`, `token.json`, `config.json`, `firmware/`). The
  YouTube automation needs `token.json` present on the target host.
- **REDRUM is built from pinned nixpkgs** (`nixpkgs-redrum`, rev `cac0c1ef`)
  because `linux >= 6.18.47` breaks the t2linux patchset. Do not "fix" this
  without reading `modules/hosts/REDRUM/T2-PIN.md` and re-checking
  `NixOS/nixos-hardware#2027` (row 2 of the registry above). Anything on that
  host that must track upstream security fixes is overridden explicitly —
  currently `services.cloudflared.package` in `modules/server/cloudflared.nix`
  pins Cloudflare's release binary (bump `version` + `hash` there); drop such
  overrides with the pin, or as soon as a `nixpkgs` bump covers them.
- **Do not add a `nix flake check` step** back into `rebuild.sh` — the live
  rebuild feed is intentionally streamed through `bat` and only errors are shown
  on failure (see the `PIPESTATUS` handling).
- `system.stateVersion` differs per host — leave it alone unless you know what
  you're doing.
- `rebuild.sh` calls `git add --all` and auto-commits with generation metadata
  (`HOST: <generation> … || <message>`). Keep commit subjects in this format
  when committing manually.
- `stylix.enableReleaseChecks = false` is set in host `home.nix` files to avoid
  the release-mismatch error — keep it consistent across hosts.
- **REDRUM does not import `essentials/users.nix`** — it defines its own
  `users.users.cairo` in `hosts/REDRUM/machine.nix`, so anything the shared
  users module sets (currently `shell = pkgs.zsh`) must be duplicated there.
  Without `shell = pkgs.zsh`, SSH sessions land in bash and none of the
  home-manager zsh config (aliases `rebuild`/`config-sync`/`cd = "z"`, zoxide
  integration) loads. **Do not "fix" this by importing the shared module on
  REDRUM**: it sets `extraGroups = [ … "seat" … "plugdev" ]` and those groups
  are not created by any module REDRUM imports (they exist on the desktop
  hosts only), so user activation fails with `group does not exist` and the
  switch aborts — and it would also enable `hardware.uinput` + the uinput/input
  groups for xremap, which a headless server never uses. When changing
  `essentials/users.nix`, mirror the change in REDRUM's user block.
- **pnpm `packageManager` pins in server FODs** — pnpm's
  `manage-package-manager-versions` self-downloads whatever version
  `package.json` pins whenever it differs from the running `pkgs.pnpm`; that
  fetch fails inside the build sandbox (`Failed to switch pnpm to vX … ENOENT`)
  and silently makes a "fixed-output" derivation depend on a second registry
  download of a pnpm binary. This broke the abt-sidecar deps FOD on
  2026-10-20; the fix (strip `packageManager` with the node one-liner before
  the first pnpm command, re-fetch the FOD hash) is in
  `modules/server/actual-budget-tweaks.nix`. `modules/server/reactflux.nix` is
  currently safe only because its pin (`pnpm@11.21.0`) equals the pinned
  nixpkgs' `pkgs.pnpm` — when bumping either pnpm project, or when the T2 pin
  is lifted (T2-PIN.md step 3), apply the same strip and re-fetch the hash.
- **Server pnpm FOD hashes are not reproducible** — a separate, related trap:
  both `pnpmDeps` fixed-output derivations (`actual-budget-tweaks.nix`,
  `reactflux.nix`) re-resolve **floating dep ranges** from the live npm registry
  on every fetch, so their store+metadata-cache output — and therefore
  `outputHash` — drifts over time and across the GOD-KILLER/REDRUM pins. Symptom
  is `error: hash mismatch in fixed-output derivation` on an otherwise-unchanged
  tree (observed 2026-10-20 on both FODs in one session). Immediate fix: build
  once, copy the `got:` value into `outputHash`, rebuild. Both sites carry a
  `FIXME:` block. Durable fix: replace the hand-rolled FODs with a
  lockfile-frozen fetch (`fetchPnpmDeps` / `pnpm.fetchDeps`) when the pinned
  nixpkgs ships one that works with these lockfiles.

## Documentation Maintenance

These two files describe the repo and all agents rely on them for context. Keep
them accurate:

- **Update `README.md`** when: adding/removing a host, changing the module layout
  or pattern, adding a notable feature/theme, or changing the install/rebuild
  workflow.
- **Update this `AGENTS.md`** when: conventions change (fragment naming, options,
  paths), the quick commands section becomes stale, or a new gotcha is
  discovered.
- When you make a change that affects either file, update the relevant
  documentation **in the same change**. If a task only touches docs coverage,
  refresh both files so they stay consistent (README = human overview,
  AGENTS.md = agent operational guidance).
- **`TODO.md`** is the wishlist of planned config updates (see the README's
  "Planned Updates" section). When you implement an item from it, **remove
  the item (and its sub-items) from `TODO.md` in the same change** — do not
  check it off, do not leave it behind "for reference".