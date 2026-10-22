# Phase 0 — NVIDIA spike runbook

Goal: prove Waydroid + the ATV image run on GOD-KILLER's proprietary NVIDIA
stack before building the `waydroid-tv` module.

The ATV images are already fetched into the Nix store (hash-pinned, see
[PLAN.md](./PLAN.md#decisions-locked-with-the-user)):

- system (GAPPS): `/nix/store/0mir7hkikihy37ffg63rlyc3h1qnc7vx-lineage-24.0-20261017-GAPPS-waydroid_x86_64-system.zip`
- system (VANILLA): `/nix/store/m9czsmara4531n2cvbdibs2s4qb0nmn7-lineage-24.0-20261017-VANILLA-waydroid_x86_64-system.zip`
- vendor (MAINLINE): `/nix/store/0qx3pqpfbxaszss4ly0c8zgv87mzpbr9-lineage-24.0-20261017-MAINLINE-waydroid_x86_64-vendor.zip`

> [!IMPORTANT]
> **Pin `20261017`, not `20260403`.** The `20260403` build we tested first
> predates two upstream fixes that match our failure exactly:
>
> - [waydroid-builds#17](https://github.com/WayDroid-ATV/waydroid-builds/issues/17)
>   — "Boot loop happening with latest A16 image" on **AMD GPUs**
>   (Ryzen 5 5600G, Vega). Fixed in release `20260717`.
> - Release `20261017` notes: *"Fixed crashing on non-wlroots Wayland
>   compositors"* and *"Use `minigbm_gbm_mesa` on AMD GPUs by default for
>   better compatibility"*.
>
> Our host renders Waydroid on the **AMD iGPU** (`/dev/dri/renderD129`,
> amdgpu) because Waydroid's GPU probe skips `nvidia` — and Hyprland runs on
> the **NVIDIA** GPU. That is exactly the configuration those fixes address.
> `20260403` produced "Android with user 0 is ready" → black window →
> SurfaceFlinger/container teardown. Do not re-test the old pin.

> [!IMPORTANT]
> Never run `sudo waydroid init -f` while `/etc/waydroid-extra/images/` exists
> but is empty. Waydroid 1.6.3's `initializer.py:55` does
> `os.path.isfile(path) or stat.S_ISBLK(os.stat(path).st_mode)` — the
> `os.stat()` raises `FileNotFoundError` on the missing image instead of
> falling through to the "missing system or vendor image, ignoring" branch.
> The symptom is
> `ERROR: [Errno 2] No such file or directory: '/etc/waydroid-extra/images/system.img'`.
> Fix: `sudo rm -rf /etc/waydroid-extra` (remove the *directory*, not just its
> contents) so the preinstalled-image probe is skipped and `init` falls back to
> downloading from `ota.waydro.id` into `/var/lib/waydroid/images`.

## Steps

The whole install is scripted — **one command** (needs sudo):

```bash
sudo ~/.nixos/modules/scripts/waydroid-atv-install.sh
```

To test the VANILLA build instead of GAPPS:

```bash
sudo ~/.nixos/modules/scripts/waydroid-atv-install.sh \
	--system /nix/store/m9czsmara4531n2cvbdibs2s4qb0nmn7-lineage-24.0-20261017-VANILLA-waydroid_x86_64-system.zip
```

Manual equivalent, if you prefer to run the steps by hand:

```bash
# 1. Activate the reintegrated Waydroid module (pick GOD-KILLER)
cd ~/.nixos && ./rebuild.sh

# 2. (recommended) reboot so the new kernel params take effect (psi=1)
#    and waydroid-container starts from a clean boot
sudo reboot

# 3. Stop the container and clear the stale 20260403 images
sudo systemctl stop waydroid-container || true
sudo rm -rf /etc/waydroid-extra
sudo rm -rf /var/lib/waydroid/overlay* /var/lib/waydroid/userdata.img

# 4. Install the pinned 20261017 ATV images (root: waydroid init needs it)
sudo mkdir -p /etc/waydroid-extra/images
sudo unzip -o /nix/store/0mir7hkikihy37ffg63rlyc3h1qnc7vx-lineage-24.0-20261017-GAPPS-waydroid_x86_64-system.zip -d /etc/waydroid-extra/images
sudo unzip -o /nix/store/0qx3pqpfbxaszss4ly0c8zgv87mzpbr9-lineage-24.0-20261017-MAINLINE-waydroid_x86_64-vendor.zip -d /etc/waydroid-extra/images
ls -lh /etc/waydroid-extra/images       # expect system.img (~1.7G) + vendor.img (~690M)

# 5. Initialise Waydroid against the ATV images
sudo waydroid init -f

# 6. Skip ATV's Bluetooth-remote pairing wizard — the container has no Bluetooth;
#    remotes are paired on the Linux side instead (see PLAN.md)
echo atv.setup.bt_remote_pairing=false | sudo tee -a /var/lib/waydroid/waydroid_base.prop

# 7. Make sure the container is up (it is also enabled at boot)
sudo systemctl start waydroid-container
waydroid status                          # container: RUNNING, session: STOPPED

# 8. The actual test — inside the Hyprland session
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
- **`waydroid init -f` fails with `[Errno 2] ... system.img`** — see the
  IMPORTANT box at the top: remove `/etc/waydroid-extra` entirely.
- **`waydroid init -f` "succeeds" but downloads nothing** — `init` only
  downloads when `images_path` is *not* one of the preinstalled paths
  (`/etc/waydroid-extra/images`, `/usr/share/waydroid-extra/images`); with a
  preinstalled path it just symlinks/copies the existing images and sets
  `waydroid.updater.disabled=true`.
- **Binding/`binder` errors** — the kernel config assertion passed at eval
  time, but check `ls /dev/binder*` and `dmesg | grep -i binder`.
- **Input doesn't reach the window** — click the window first (focus), then
  retry; note which keys work.
- **Still black on `20261017`** — capture the real stack trace before
  concluding it is the image:
  `waydroid logcat` while the session is starting, plus
  `journalctl -u waydroid-container -n 200 --no-pager`. Compare against
  [waydroid#2436](https://github.com/waydroid/waydroid/issues/2436)
  (vendor hotplug loop → SurfaceFlinger SIGSEGV) and
  [waydroid#2387](https://github.com/waydroid/waydroid/issues/2387)
  ("Android with user 0 is ready" → no window on Wayland).

## Phase 0 exit criteria

All unchecked boxes in [PLAN.md → Phase 0 status](./PLAN.md#phase-0-status)
are checked. When resuming later, follow this document from step 1. Then
Phase 1 (`modules/system/waydroid-tv.nix`) can start.

## Resume checklist (quick copy)

- [ ] Run rebuild: `cd ~/.nixos && ./rebuild.sh` → GOD-KILLER
- [ ] Reboot (recommended)
- [ ] `sudo ~/.nixos/modules/scripts/waydroid-atv-install.sh`
- [ ] `waydroid show-full-ui` in Hyprland and test keyboard + navigation
- [ ] Capture evidence and report back (see below)
