# Module recipes

Step-by-step recipes referenced from [AGENTS.md](../../AGENTS.md#the-module-pattern-how-to-add-a-feature).
Read the one you need before creating a server module, theming the ABT sidecar
or archiving a module.

## Creating a server module (REDRUM)

`modules/server/*.nix` each define an app on REDRUM, exposed through a
Cloudflare tunnel. Follow the existing modules (`linkwarden.nix`,
`actual-budget.nix`, `minsiflux.nix`) — each one **must**:

1. **Pick a free local port** (in use: glance 8081, homepage 8082, linkwarden 8083,
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
   The tunnel UUID is an **identifier, not a secret**: once `cloudflared tunnel
   create <app>` has made the tunnel, commit its real UUID here (all eight
   existing tunnels in `modules/server` are). The secret is the credentials JSON in
   `/var/lib/cloudflared/<app>.json`, which is never committed. Until the tunnel
   exists, use a placeholder UUID marked with a `# TODO:` comment. Keep the shared
   `hostname → port` table in the README accurate, and list the app in the
   Homepage Homelab tab (`modules/server/homepage.nix` is a config fragment of
   its own) if it should show there.

5. **Wire and document**: add `inputs.self.modules.nixos."<name>"` to the REDRUM
   module list in `modules/hosts/host.nix`, then update the README: the feature bullet, the tunnel create/credential steps, the DNS CNAME table, the
   permissions table (`/var/lib/<app>` row) and the "log in once" notes.

6. **Static frontends** (e.g. ReactFlux, a pnpm/Vite SPA): package the build as a
   `pkgs.stdenv.mkDerivation` and serve the store path straight from nginx —
   no app user needed. For pnpm projects, follow `reactflux.nix`: an immutable
   fixed-output `pnpm install` must run **with network** (that's the only place
   the registry is touched), then the real build installs `--offline` against a
   *copied* (writable) store **and** metadata cache. Neither `fetchPnpmDeps` nor
   `buildPnpmPackage` exist in the pinned nixpkgs on REDRUM — hand-roll both.
   `nix flake check` on REDRUM is not part of the loop; verify with
   `nix eval '.#nixosConfigurations.REDRUM.config.system.build.toplevel.drvPath'`.

## Theming the Actual Budget Tweaks sidecar

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

## Archiving a module (required steps)

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
