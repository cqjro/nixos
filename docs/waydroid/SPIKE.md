# Phase 0 — NVIDIA spike runbook

Goal: prove Waydroid + the ATV image run on GOD-KILLER's proprietary NVIDIA
stack before building the `waydroid-tv` module.

The ATV images are already fetched into the Nix store (hash-pinned, see
[PLAN.md](./PLAN.md#pinned-image-20260403-gapps)):

- system (GAPPS): `/nix/store/d3phxj7516ar3dckslp3s58pikcbvpcl-lineage-23.0-20260403-GAPPS-waydroid_tv_x86_64-system.zip`
- vendor (MAINLINE): `/nix/store/57kshimb1z06q8a1jla1ac944sgmjs27-lineage-23.0-20260403-MAINLINE-waydroid_tv_x86_64-vendor.zip`

## Steps

```bash
# 1. Activate the reintegrated Waydroid module (pick GOD-KILLER)
cd ~/.nixos && ./rebuild.sh

# 2. (recommended) reboot so the new kernel params take effect (psi=1)
#    and waydroid-container starts from a clean boot
sudo reboot

# 3. Install the pinned ATV images (root: waydroid init needs it)
sudo mkdir -p /etc/waydroid-extra/images
sudo unzip -o /nix/store/d3phxj7516ar3dckslp3s58pikcbvpcl-lineage-23.0-20260403-GAPPS-waydroid_tv_x86_64-system.zip -d /etc/waydroid-extra/images
sudo unzip -o /nix/store/57kshimb1z06q8a1jla1ac944sgmjs27-lineage-23.0-20260403-MAINLINE-waydroid_tv_x86_64-vendor.zip -d /etc/waydroid-extra/images
ls -lh /etc/waydroid-extra/images       # expect system.img (~1.5G) + vendor.img

# 4. Initialise Waydroid against the ATV images
sudo waydroid init -f

# 5. Skip ATV's Bluetooth-remote pairing wizard — the container has no Bluetooth;
#    remotes are paired on the Linux side instead (see PLAN.md)
echo atv.setup.bt_remote_pairing=false | sudo tee -a /var/lib/waydroid/waydroid_base.prop

# 6. Make sure the container is up (it is also enabled at boot)
sudo systemctl start waydroid-container
waydroid status                          # container: RUNNING, session: STOPPED

# 7. The actual test — inside the Hyprland session
waydroid show-full-ui
```

## Pass criteria

- `waydroid status` reports container RUNNING.
- `waydroid show-full-ui` opens a window showing the Android TV launcher
  (not a black/white screen, no EGL/GBM errors).
- Typing on the keyboard and pressing arrow keys navigates the ATV launcher.

## If it fails

Collect the evidence, then report back:

```bash
waydroid status
waydroid log --details-to-stdout | tail -100
sudo journalctl -u waydroid-container -n 100 --no-pager
```

- **Black screen / EGL errors on NVIDIA** — known Waydroid pain point; stop
  here and research (waydroid nvidia GBM/gralloc workarounds) before any
  module work.
- **Binding/`binder` errors** — the kernel config assertion passed at eval
  time, but check `ls /dev/binder*` and `dmesg | grep -i binder`.
- **Input doesn't reach the window** — click the window first (focus), then
  retry; note which keys work.

## Phase 0 exit criteria

All unchecked boxes in [PLAN.md → Phase 0 status](./PLAN.md#phase-0-status)
are checked. When resuming later, follow this document from step 1. Then
Phase 1 (`modules/system/waydroid-tv.nix`) can start.

## Resume checklist (quick copy)

- [ ] Run rebuild: `cd ~/.nixos && ./rebuild.sh` → GOD-KILLER
- [ ] Reboot (recommended)
- [ ] Copy images from store paths in this doc to `/etc/waydroid-extra/images/`
- [ ] `sudo waydroid init -f`
- [ ] `echo atv.setup.bt_remote_pairing=false | sudo tee -a /var/lib/waydroid/waydroid_base.prop`
- [ ] `sudo systemctl start waydroid-container && waydroid status`
- [ ] `waydroid show-full-ui` in Hyprland and test keyboard + navigation
- [ ] Capture evidence and report back (see below)
