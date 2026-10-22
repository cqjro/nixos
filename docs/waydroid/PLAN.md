# Waydroid Android TV — implementation plan

Session: `ses_ea40b3490ffehrTKIy93qWd1fs` (opencode, 2026-10-20/21)

Goal: turn GOD-KILLER into a pseudo Android TV — Waydroid with the
[WayDroid-ATV](https://github.com/WayDroid-ATV/waydroid-androidtv-builds)
Android TV image, available **both** as a greeter session (kiosk, like the
Hyprland/Steam entries) and as a desktop app window inside Hyprland.

This folder collects everything Waydroid/Android TV related: the plan, spike
notes, pinned image hashes, remote-pairing notes.

## Decisions (locked with the user)

| Decision | Choice |
| --- | --- |
| Host | **GOD-KILLER only** (NVIDIA proprietary is the top risk — spike first) |
| Boot behaviour | module option `waydroid-tv.autologin` — **default off** (greeter flow unchanged; option on = greetd `initial_session` straight into TV) |
| Image provisioning | **Pinned Nix FODs** — both release zips fetched with hashes into the store; first-boot oneshot installs them. Bump = edit url+hash. |
| Image flavour | **GAPPS build** (`20261017`, Android TV 17 / LineageOS 24.0). Google TV mode is left **off** (default) — it's a runtime toggle inside the image (Settings → System → Waydroid options → Google TV mode), not an image choice. |
| BT remote | iPazzPort air mouse / BT universal remote — **not delivered yet**; verify shortly after arrival |

## Feasibility findings (research, 2026-10-20)

- **Declarative image — yes.** WayDroid-ATV publishes versioned GitHub release
  assets (e.g. `lineage-24.0-20261017-GAPPS-waydroid_x86_64-system.zip`
  ~1.4 GB + `…-MAINLINE-…-vendor.zip` ~249 MB). `virtualisation.waydroid` has
  no image options, so we `fetchurl` the zips, extract `system.img` /
  `vendor.img`, drop them in `/etc/waydroid-extra/images/` (the documented
  custom-image path) and run `waydroid init -f` from a guarded systemd
  oneshot. Only `init`/`upgrade`/`shell` need root; `session`/`app`/
  `show-full-ui` run as the user (verified in waydroid source).
- **Greeter session — yes, same mechanism as hyprland/steam.** noctalia-greeter
  is greetd-based and lists sessions from
  `services.displayManager.sessionPackages` (assembled into
  `sessionData.desktops`, injected via `XDG_DATA_DIRS` — visible in the
  generated `greetd.toml`; today: hyprland, hyprland-uwsm, steam). A
  `share/wayland-sessions/waydroid-tv.desktop` package with
  `passthru.providedSessions` (the `steam.nix` pattern) shows up in the picker
  automatically. Its Exec runs Waydroid's documented "Waydroid-only session":
  `cage waydroid show-full-ui` — `show-full-ui` auto-starts the session under
  cage's Wayland display.
- **Desktop app — yes.** A `.desktop` launcher running `waydroid show-full-ui`
  opens the TV UI as a window inside Hyprland; both modes share the same
  Android user data.
- **Autologin kiosk — yes.** greetd supports `settings.initial_session`
  (nixpkgs greetd module handles the getty conflict when it is set). Logout /
  VT-switch still reaches the greeter.
- **Aurora + APKs — yes, pinned.** Aurora 4.8.4 on F-Droid at
  `https://f-droid.org/repo/com.aurora.store_76.apk` (hash-pinned). Idempotent
  "ensure apps" helper: wait for session RUNNING, then
  `waydroid app install <apk>` for anything without an install marker. Any
  stable-URL APK (F-Droid repo, GitHub releases: SmartTube, Kodi, …) can be
  pinned. Apps installed *inside* Android from Play Store/Aurora stay
  imperative — that boundary is by design.
- **Bluetooth remote — yes, host-side pairing only.** Waydroid has **no
  Bluetooth inside the container** (upstream #155, #2041, #2125; hence the ATV
  image's documented `atv.setup.bt_remote_pairing=false` workaround). Pair the
  remote with Linux BlueZ → it becomes a normal HID keyboard/pointer → the
  compositor (Hyprland or cage) feeds key events into the Waydroid window.
  Works in both modes. Remote must be standard BLE HID (2.4 GHz dongle models
  are plain USB HID — even simpler).

## Target design

New/reintegrated files:

- `modules/system/waydroid.nix` — reintegrated from
  `modules/_archive/waydroid.nix` (base: `virtualisation.waydroid.enable`,
  `waydroid`, `waydroid-helper`).
- `modules/system/waydroid-tv.nix` — `flake.modules.nixos."waydroid-tv"` with
  `mkIf enable` options:
  - `waydroid-tv.enable`, `waydroid-tv.autologin` (default false),
    `waydroid-tv.apks` (default: Aurora fetchurl).
  - Image pin (GAPPS `20260403`; VANILLA `20260403` fetched for NVIDIA/testing) → `runCommand` unzip → store dir.
  - `systemd.services.waydroid-atv-provision` (oneshot, required before
    `waydroid-container.service`, marker `/var/lib/waydroid/.nix-atv-image`
    holds the image-drv hash so a pin bump re-provisions): tmpfiles-create
    `/etc/waydroid-extra/images`, copy images, `waydroid init -f`, idempotently
    append `atv.setup.bt_remote_pairing=false` to `waydroid_base.prop`, touch
    marker.
  - Session script (`writeShellApplication`, waydroid+cage): wait for container
    active (clear error + exit → greetd falls back to greeter) →
    `waydroid session stop || true` → background ensure-apps loop → `exec cage
    -- waydroid show-full-ui`.
  - `share/wayland-sessions/waydroid-tv.desktop` +
    `passthru.providedSessions = [ "waydroid-tv" ]` →
    `services.displayManager.sessionPackages`.
  - App mode: `waydroid-tv-app` launcher + `share/applications/` entry
    (container check → ensure-apps → `waydroid show-full-ui`).
  - `autologin = true` → `services.greetd.settings.initial_session = {
    command = <session script>; user = "cairo"; }`.
- `modules/hosts/host.nix` — GOD-KILLER gets
  `inputs.self.modules.nixos.waydroid` + `...waydroid-tv` + an attrset module
  enabling it (abt-sidecar pattern).

## Phases

### Phase 0 — NVIDIA spike (gate) ← *current*

1. Reintegrate the archived module, wire into GOD-KILLER, rebuild.
2. Manual ATV image install: fetch the two zips, extract to
   `/etc/waydroid-extra/images/`, `sudo waydroid init -f`, append the
   `bt_remote_pairing=false` prop.
3. Run `waydroid show-full-ui` under Hyprland. **Pass criteria:** binder
   assertions pass, ATV renders (no black screen), keyboard input reaches
   Android. If NVIDIA fails, stop and research before writing the module.

### Phase 1 — `waydroid-tv.nix`
Image pin + provisioning oneshot + session script + greeter entry + app
launcher + `autologin` option.

### Phase 2 — Declarative apps
`waydroid-tv.apks` (Aurora default) + ensure-apps logic in both wrappers.

### Phase 3 — Bluetooth remote
Docs/pairing steps; verify when the iPazzPort arrives (HID enumeration, D-pad
+ air-mouse in both modes; watch `persist.waydroid.uevent` for double input).

### Phase 4 — Ad-free modern UI (exploration)
Default state already avoids Google TV ads: GAPPS build ships Google TV
components disabled → basic TV launcher. If a nicer launcher is wanted:
pin a third-party TV launcher APK in `apks` and/or debloat the Google TV home
(`pm disable-user …`) from the provision/ensure step when Google TV mode is
toggled on later.

### Phase 5 — Docs & cleanup
README feature bullet + remote pairing + pin-bump instructions; AGENTS gotcha
(pin bumps between ATV major releases may need the documented user-data wipe;
provisioning marker mechanics); remove the Android TV item from `TODO.md`.

## Risks / caveats

- **NVIDIA** (GOD-KILLER renders through proprietary NVIDIA): historically
  Waydroid's pain point; ATV builds call NVIDIA support "experimental,
  untested". Phase 0 gate.
- Disk/store cost ≈ 4 GB (pinned zips + extracted images + `/var/lib` copy).
- Standalone session owns the seat — TV and Hyprland are alternative logins;
  app mode is the "both at once" path (per-monitor use).
- `cage` cannot pin itself to a specific monitor; fallback is a sway-based
  kiosk script with an `output` line.
- Bumping the ATV pin across major releases can require the project's
  documented storage wipe (`rm -rf ~/.local/share/waydroid
  /var/lib/waydroid/overlay* && sudo waydroid init -f`).
- Some apps refuse to run on Waydroid (Play Integrity/DRM); Widevine L3 is
  present in the x86-64 build but not L1.

## Phase 0 status

- [x] Reintegrate `modules/system/waydroid.nix`
- [x] Wire into GOD-KILLER in `host.nix`
- [x] Eval/rebuild passes (binder kernel config assertion)
- [x] ATV images fetched + hashes recorded (see [SPIKE.md](./SPIKE.md))
- [x] ATV images copied to `/etc/waydroid-extra/images/` + `waydroid init -f` run
- [ ] `atv.setup.bt_remote_pairing=false` appended to `waydroid_base.prop`
- [ ] `waydroid show-full-ui` renders under Hyprland (NVIDIA check)
- [ ] Keyboard/D-pad input reaches Android TV

### Black-screen triage (2026-10-21)

Both ATV flavours (`20260403` GAPPS and `20260403` VANILLA) failed
identically: container boots, logs `Android with user 0 is ready`, then the
window is black and the container is torn down (SurfaceFlinger crash).

Root cause identified — **the `20260403` pin was stale**, not the hardware:

- Waydroid's GPU probe skips `nvidia` (unsupported list), so it auto-selects
  the **AMD iGPU** `/dev/dri/renderD129` → `ro.hardware.egl=mesa`,
  `ro.hardware.vulkan=radeon`, `gralloc.gbm.device=/dev/dri/renderD129`.
  Hyprland itself runs on the **NVIDIA** GPU, so the container renders on a
  *different* GPU than the compositor.
- [waydroid-builds#17](https://github.com/WayDroid-ATV/waydroid-builds/issues/17)
  ("Boot loop happening with latest A16 image") is an **AMD GPU** boot loop,
  fixed in release `20260717`.
- Release `20261017` notes: *"Fixed crashing on non-wlroots Wayland
  compositors"* and *"Use `minigbm_gbm_mesa` on AMD GPUs by default for better
  compatibility"*.

`20260403` predates both. The pin has been bumped to **`20261017`**
(LineageOS 24.0 / Android TV 17) for all three images; hashes are in
`.prefetch-system.json`, `.prefetch-system-vanilla.json` and
`.prefetch-vendor.json`.

Secondary finding (independent bug, still open upstream): Waydroid 1.6.3's
`tools/actions/initializer.py:55` calls `os.stat()` on a possibly-missing
image and raises `FileNotFoundError` instead of falling through to the
"missing image" branch. Workaround: remove `/etc/waydroid-extra` entirely
before `waydroid init -f`. See the IMPORTANT box in [SPIKE.md](./SPIKE.md).

**Resume instructions (for a later session):** Follow [SPIKE.md](./SPIKE.md) end-to-end. Report back with `waydroid status`, `waydroid log --details-to-stdout | tail -100`, `waydroid logcat` (captured *during* the boot attempt, for the real SurfaceFlinger stack trace), and `sudo journalctl -u waydroid-container -n 100 --no-pager`. If all criteria pass, Phase 0 exits and Phase 1 begins.
