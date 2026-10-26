# Waydroid / Android TV — index

- [PLAN.md](./PLAN.md) — full implementation plan, decisions, architecture,
  phases and risks (session `ses_ea40b3490ffehrTKIy93qWd1fs`).
- [SPIKE.md](./SPIKE.md) — Phase 0 NVIDIA spike runbook (images already
  fetched/pinned for 20261017 GAPPS + MAINLINE vendor).
- Prefetch outputs (for reference): `.prefetch-system.json`,
  `.prefetch-system-vanilla.json`, `.prefetch-vendor.json`
- **Current state (2026-10-25):** Android TV 17 boots; the black window is a
  confirmed host cross-GPU limitation (display on NVIDIA, Waydroid on the AMD
  iGPU), not an image/prop bug. Resume from
  [PLAN.md → Handoff](./PLAN.md#handoff--paused-2026-10-25).

The base reintegrated module lives at `modules/system/waydroid.nix`.
The feature module will go in `modules/system/waydroid-tv.nix`.
Wiring: GOD-KILLER only (`modules/hosts/host.nix` already includes
`inputs.self.modules.nixos.waydroid`).


## Reset Android data (factory reset)

Android's userdata is **`~/.local/share/waydroid`**, not
`/var/lib/waydroid/userdata.img`. `waydroid init -f`, replacing the images and
clearing the overlays do not touch it. Old data from a different Android
release makes `zygote`/`system_server` crash-loop (symptoms: Container
RUNNING, IP `UNKNOWN`, kernel log repeating `zygote ... exited 4 times before
boot completed`). For a data-only reset (images unchanged):

```bash
waydroid session stop
rm -rf ~/.local/share/waydroid          # no sudo: it is your own data
sudo rm -rf /var/lib/waydroid/overlay*
sudo systemctl start waydroid-container
waydroid show-full-ui
```

If the images were also replaced, use
`modules/scripts/waydroid-atv-install.sh` instead — it wipes the data, extracts
the pinned images, runs `init -f`, and re-applies the AMD/ATV props.

## Restart + test after prop changes (AMD, minigbm)
Exact steps used on GOD-KILLER (Hyprland on NVIDIA, Waydroid on AMD iGPU):

1. Stop session and container
```bash
waydroid session stop 2>/dev/null || true
sudo systemctl stop waydroid-container 2>/dev/null || true
```

2. Ensure props point to AMD render node + minigbm
   Verify `/var/lib/waydroid/waydroid.prop` contains:
```conf
gralloc.gbm.device=/dev/dri/renderD129
ro.hardware.egl=mesa
ro.hardware.vulkan=radeon
ro.hardware.gralloc=minigbm_gbm_mesa
atv.setup.bt_remote_pairing=false
```
   If you ran `waydroid init -f` recently, also update `/var/lib/waydroid/waydroid_base.prop`.

3. Confirm render nodes
```bash
for node in /dev/dri/renderD*; do
  drv=$(basename "$(readlink -f "$(udevadm info -q path -n "$node")/device/driver" 2>/dev/null)")
  echo "$node -> $drv"
done
# expect: renderD128 -> nvidia, renderD129 -> amdgpu
```

4. Start container and test UI
```bash
sudo systemctl start waydroid-container
sleep 15
waydroid status
waydroid show-full-ui
```

5. Debug if black screen
```bash
journalctl -u waydroid-container -n 80 --no-pager
tail -60 /var/lib/waydroid/waydroid.log
```

Notes:
- `/dev/dri/renderD129` = AMD iGPU (correct). `/dev/dri/renderD128` = NVIDIA (do not use).
- `ro.hardware.gralloc=minigbm_gbm_mesa` is required for 20261017 ATV on AMD.
- Cross-GPU is **confirmed** on this host: compositor on NVIDIA, container on
  the AMD iGPU → black window even with correct props. Boot is healthy; the
  fix is a display-topology/upstream issue, not a Waydroid setting. See
  [PLAN.md → Handoff](./PLAN.md#handoff--paused-2026-10-25).
