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
3. `rm modules/hosts/REDRUM/T2-PIN.md`
4. `nix flake lock --update-input nixpkgs-redrum` (or let it drop), then
   rebuild REDRUM to confirm it builds on current nixpkgs.