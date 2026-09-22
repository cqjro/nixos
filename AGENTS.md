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
  system/          # games, minecraft, waydroid, ios-sideloading, vpn, manifest, rss-sources, …
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

## Gotchas

- **Secrets and firmware are gitignored** and must never be committed
  (`client_secret.json`, `token.json`, `config.json`, `firmware/`). The
  YouTube automation needs `token.json` present on the target host.
- **REDRUM is built from pinned nixpkgs** (`nixpkgs-redrum`, rev `cac0c1ef`)
  because `linux >= 6.18.47` breaks the t2linux patchset. Do not "fix" this
  without reading `modules/hosts/REDRUM/T2-PIN.md`.
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