# REDRUM T2 kernel pin — REMOVE AFTER UPSTREAM FIX

## Status
Active. Workaround for the broken REDRUM/LittleNix kernel build.

## What is pinned
- **flake input** `nixpkgs-redrum` in `flake.nix`, locked to
  `github:NixOS/nixpkgs/cac0c1ef61ab13dc82e5368e34de132a74336d79`
  (2026-08-23) — the last rev whose `linux_6_18` is still **6.18.46**.
- **host.nix**, REDRUM block: the whole host is built with
  `inputs.nixpkgs-redrum.lib.nixosSystem` instead of the shared
  `inputs.nixpkgs.lib.nixosSystem`.

The location carries a `# TODO-remove:` comment.

## Knock-on effects elsewhere in the tree
The pin is *not* inherited by everything — packages that must track upstream
(security fixes) are overridden explicitly on REDRUM:

- **`cloudflared`** — `services.cloudflared.package` in
  `modules/server/cloudflared.nix` is pinned to Cloudflare's own release binary
  (`cloudflaredPinned`, currently 2026.10.2) instead of the pinned nixpkgs'
  2026.7.3 — the locked `nixpkgs` input only reaches 2026.10.1, which lagged a
  security release. The override carries a `# TODO-remove:`; delete it with the
  pin, or earlier once `nixpkgs` is bumped (master already ships 2026.10.3).
- **`tailscale`** — `services.tailscale.package` in
  `modules/server/tailscale.nix` is pinned to 1.104.4 instead of the pinned
  nixpkgs' 1.102.2. The pin is built from the main `nixpkgs` input's package
  recipe because the pinned rev's Go (1.26.5) is too old for tailscale 1.104.4
  (`go.mod` wants >= 1.27.3); that input still ships 1.104.2 as of channel
  2026-10-27. The override carries a `# TODO-remove:`; delete it once both
  inputs ship >= 1.104.4.
- **`t3code`** — `modules/server/t3code.nix` runs the server from the main
  `nixpkgs` input (same build as GOD-KILLER) instead of the pinned nixpkgs'
  0.0.33, because the desktop client rejects older servers ("This client
  requires a newer server"). The override carries a `# TODO-remove:`; delete it
  with the pin.
- **`claude-code`** — `modules/server/t3code.nix` also takes the `claude` CLI
  from the main `nixpkgs` input (2.1.308) instead of the pinned nixpkgs'
  2.1.238: T3 gates each Claude model on a minimum CLI version (up to 2.1.293),
  so the older CLI left REDRUM with only the legacy model. The override carries
  a `# TODO-remove:`; delete it with the pin.

## Why
`linux_6_18 >= 6.18.47` no longer accepts the `facf1c7` t2linux patchset
shipped by `nixos-hardware`'s apple-t2 module (patch `4001` hunk fails).
Upstream tracked in: `NixOS/nixos-hardware#2027` (a stale
`stable.json` pin; t2linux itself fixed the patches at `1ed4126`).

Note: a `nixpkgs.pkgs`-only override was tried first but fails because the
system's NixOS modules (from current nixpkgs) reference package attrs missing
in the pinned set; pinning the whole `nixosSystem` avoids that skew.

## When to remove
When apple-t2 works on stock `nixpkgs/nixos-unstable` again, i.e. once
nixos-hardware#2027 is resolved (or the pin is otherwise obsolete). Verify by
checking the upstream issue, then rebuild REDRUM without the pin.

## How to remove
1. `flake.nix`: delete the `nixpkgs-redrum` input (and its comment block).
2. `modules/hosts/host.nix`: in the REDRUM block, change
   `inputs.nixpkgs-redrum.lib.nixosSystem` back to
   `inputs.nixpkgs.lib.nixosSystem` and delete the comment block above it.
3. `modules/server/cloudflared.nix`: delete `cloudflaredPinned` and the
   `services.cloudflared.package` line (plus their comments) — the host's
   `pkgs.cloudflared` is current again after step 2.
4. `modules/server/actual-budget-tweaks.nix`: `pkgs =
   inputs.nixpkgs-redrum.legacyPackages.${system}` must become
   `inputs.nixpkgs.legacyPackages.${system}` (the input no longer exists). The
   sidecar's `abtSidecarPnpmDeps` FOD hash will drift with the build toolchain —
   rebuild once and copy the "got" hash, as with the reactflux FOD below.
5. `modules/server/reactflux.nix`: the pinned nixpkgs ships
   `pkgs.pnpm == 11.21.0`, which matches the project's `packageManager`
   pin — so pnpm never self-downloads a second version. Stock nixpkgs ships
   a different pnpm, so after unpinning, strip the `packageManager` field
   from `package.json` in BOTH the `pnpmDeps` FOD and the `reactflux`
   build (copy the node one-liner from
   `modules/server/actual-budget-tweaks.nix`) and re-fetch the FOD
   `outputHash` (build with the wrong hash once, copy the "got" hash).
   Without this, the next deps rebuild fails in the sandbox with
   `Failed to switch pnpm to v… ENOENT` — the same failure that broke
   abt-sidecar's FOD on 2026-10-20.
6. `rm modules/hosts/REDRUM/T2-PIN.md`
7. `nix flake lock --update-input nixpkgs-redrum` (or let it drop), then
   rebuild REDRUM to confirm it builds on current nixpkgs.