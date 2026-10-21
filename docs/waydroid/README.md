# Waydroid / Android TV — index

- [PLAN.md](./PLAN.md) — full implementation plan, decisions, architecture,
  phases and risks (session `ses_ea40b3490ffehrTKIy93qWd1fs`).
- [SPIKE.md](./SPIKE.md) — Phase 0 NVIDIA spike runbook (images already
  fetched/pinned for 20260403 GAPPS + MAINLINE vendor).
- Prefetch outputs (for reference): `.prefetch-system.json`, `.prefetch-vendor.json`

The base reintegrated module lives at `modules/system/waydroid.nix`.
The feature module will go in `modules/system/waydroid-tv.nix`.
Wiring: GOD-KILLER only (`modules/hosts/host.nix` already includes
`inputs.self.modules.nixos.waydroid`).
