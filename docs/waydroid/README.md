# Waydroid / Android TV — index

- [PLAN.md](./PLAN.md) — full implementation plan, decisions, architecture,
  phases and risks (session `ses_ea40b3490ffehrTKIy93qWd1fs`).
- [SPIKE.md](./SPIKE.md) — Phase 0 NVIDIA spike runbook (images already
  fetched/pinned for 20261017 GAPPS + MAINLINE vendor).
- Prefetch outputs (for reference): `.prefetch-system.json`,
  `.prefetch-system-vanilla.json`, `.prefetch-vendor.json`

The base reintegrated module lives at `modules/system/waydroid.nix`.
The feature module will go in `modules/system/waydroid-tv.nix`.
Wiring: GOD-KILLER only (`modules/hosts/host.nix` already includes
`inputs.self.modules.nixos.waydroid`).


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
- Cross-GPU (compositor on NVIDIA, container on AMD) can still result in a black screen even with correct props.
