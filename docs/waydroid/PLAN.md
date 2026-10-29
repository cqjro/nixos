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
- Bumping the ATV pin across major releases requires the project's
  documented storage wipe (`rm -rf ~/.local/share/waydroid
  /var/lib/waydroid/overlay* && sudo waydroid init -f`). The important part
  is `~/.local/share/waydroid`: it is the real Android userdata and is not
  reset by `waydroid init -f` or by replacing the images. Leftover data from
  an older Android release makes `zygote`/`system_server` crash-loop (see
  below).
- Some apps refuse to run on Waydroid (Play Integrity/DRM); Widevine L3 is
  present in the x86-64 build but not L1.

## Phase 0 status

- [x] Reintegrate `modules/system/waydroid.nix`
- [x] Wire into GOD-KILLER in `host.nix`
- [x] Eval/rebuild passes (binder kernel config assertion)
- [x] ATV images fetched + hashes recorded (see [SPIKE.md](./SPIKE.md))
- [x] ATV images copied to `/etc/waydroid-extra/images/` + `waydroid init -f` run
- [ ] `atv.setup.bt_remote_pairing=false` appended to `waydroid_base.prop`
  (still absent live; the install script applies it on its next run)
- [ ] `waydroid show-full-ui` renders under Hyprland (NVIDIA check) —
  **blocked by cross-GPU; see "Handoff — paused 2026-10-25" below**
- [ ] Keyboard/D-pad input reaches Android TV (only testable once the window
  actually renders)

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

### Boot-loop root cause + fix (2026-10-25)

After installing the `20261017` images the container started but Android
never finished booting: `zygote`/`zygote_secondary` were started and killed
every ~5 s, `apexd` kept trying to revert the crashing native process, and
`waydroid show-full-ui` retried `Failed to get service waydroidplatform`.
`waydroid status` showed Container RUNNING but IP `UNKNOWN`.

Root cause: the stale `~/.local/share/waydroid` data directory left over from
the `20260403` (Android 12) image. `waydroid init -f` and the
image/overlay cleanup never touched it, so Android 17 was booting on Android
12 userdata. Removing `~/.local/share/waydroid` and restarting the session
fixed it: `system_server` came up (`Android with user 0 is ready`), the IP was
assigned, and the Waydroid window opened under Hyprland. The install script
now wipes that directory and re-applies the AMD GPU properties after
`waydroid init -f` regenerates `waydroid_base.prop`.

## Handoff — paused 2026-10-25

**Status: Android TV 17 boots completely. The remaining black window is a
confirmed host cross-GPU limitation, not an ATV/Waydroid image or prop bug.**

### What works now

- Stale userdata is gone (`~/.local/share/waydroid` was moved to
  `~/.local/share/waydroid.bak-1792981014`, 37 MB). With the `20261017`
  VANILLA system + MAINLINE vendor images the container boots cleanly:
  `Android with user 0 is ready` (22:17:13), IP `192.168.240.112`, no
  `zygote`/`system_server` crash loop.
- `waydroid show-full-ui` opens a mapped `Waydroid` window (class `Waydroid`,
  HWC pid 29244, title `Waydroid`) inside Hyprland.
- The window content is black; making it full-screen does not change it.
- The ATV container may freeze / close its window after idle (the 22:17
  session froze at 22:39 while idle). `waydroid show-full-ui` unfreezes and
  reopens it — that is normal Waydroid behaviour, not a crash.

### Session constraints

- The agent shell has **no sudo/TTY**: `waydroid logcat`/`waydroid shell` and
  edits to `/var/lib/waydroid/*.prop` need the user's password. `waydroid
  status`, `hyprctl`, `grim` and `/var/lib/waydroid/waydroid.log` are readable.

### Confirmed root cause: multi-GPU

| Component | GPU | Nodes / outputs |
| --- | --- | --- |
| Hyprland 0.56.0 (scanout) | NVIDIA RTX 4070, proprietary 595.104.02 | `card1`, `renderD128`; DP-3 + HDMI-A-1 connected |
| Waydroid (render) | AMD Raphael iGPU, amdgpu / Mesa 26.2.3 | `card0`, `renderD129`; **no** connected outputs |

Waydroid's GPU probe skips `nvidia` and picks the AMD iGPU; Hyprland
composites and scans out on NVIDIA. The AMD dmabufs the Waydroid HWC attaches
are not presented by the NVIDIA-based Hyprland, so the window stays black.
Hyprland logs **no** import error (silent black), so ATV logcat / EGL errors
are not where to look.

Controlled proof on this host (2026-10-25):

- Default `mpv` (NVIDIA, fds on `renderD128`): a red test image is visible
  (`grim` grid `ff0000`).
- The same `mpv` forced to Mesa/AMD
  (`__EGL_VENDOR_LIBRARY_FILENAMES=…/50_mesa.json`,
  `MESA_LOADER_DRIVER_OVERRIDE=radeonsi`; fds on `renderD129`,
  `GL_RENDERER=… raphael_mendocino …`): the window is black
  (`grim` grid `000000`).
- The Waydroid window crop is likewise black (`060007` / `040006` / `040005`).

Conclusion: with the display connected to NVIDIA, the ATV image cannot be
displayed while Waydroid renders on the AMD iGPU. The image, props and boot
path are correct.

### Upstream / option research

- **Aquamarine** (Hyprland's backend) does not currently allow a
  connector-less GPU to be the primary/render GPU:
  [aquamarine#359](https://github.com/hyprwm/aquamarine/issues/359) — "a GPU
  with no connectors cannot be primary".
  [aquamarine#408](https://github.com/hyprwm/aquamarine/issues/408) documents
  the inverse direction (NVIDIA primary → AMD secondary output) falling back
  to CPU readback. Neither gives us "render on AMD, scan out on NVIDIA".
- **[Hyprland#16092](https://github.com/hyprwm/Hyprland/pull/16092)** (closed,
  unmerged) adds a CPU-copy fallback for dmabufs the renderer cannot import.
  If it lands it may make AMD-rendered clients display via NVIDIA (it handles
  linear buffers; AMD tiled/modifier buffers are not guaranteed). Re-check
  before considering a local patch.
- **Waydroid-ATV** NVIDIA support is for the **nouveau** kernel driver
  (release `20260717`), not proprietary NVIDIA. Proprietary NVIDIA was on
  Waydroid's unsupported list before this and remains so.

### Next steps (when resuming)

1. **Decide the display topology with the user** (the only cheap, certain
   fix):
   - Connect the TV/monitor to the **AMD iGPU** output and run the ATV
     kiosk/Hyprland on AMD. Waydroid then renders and scans out on the same
     GPU. Downside: NVIDIA is no longer the scanout GPU (PRIME/offload needed
     for gaming; VRR/HDR behaviour changes).
   - Or keep NVIDIA scanout and defer ATV until upstream cross-GPU import
     works. No Waydroid-side change will fix it.
2. If testing the hardware route: move the cable, log into Hyprland (it will
   use `card0`), `waydroid session start`, `waydroid show-full-ui`, then
   verify with `grim` (the window should show the ATV launcher). No image
   reinstall is needed.
3. Re-check aquamarine#359/#408 and Hyprland#16092 before any local patch. A
   patched Hyprland is a large, fragile change; do not start it casually.
4. Optional, only on a disposable prop copy: try forcing Waydroid onto NVIDIA
   (`gralloc.gbm.device=/dev/dri/renderD128`, `ro.hardware.gralloc=gbm`, maybe
   SwiftShader/Zink). Proprietary NVIDIA is unsupported; expect failure.
   Restore `waydroid.prop` / `waydroid_base.prop` from the backups afterward.
5. When a root shell is available: append
   `atv.setup.bt_remote_pairing=false` to
   `/var/lib/waydroid/waydroid_base.prop` (still absent; the install script
   does it on its next run). Then restart the session.
6. Only after a real render works: update the Phase 0 checklist, commit the
   changed files, and start Phase 1 (`modules/system/waydroid-tv.nix`).
7. Clean up `~/.local/share/waydroid.bak-1792981014` (37 MB) once the fresh
   data no longer needs a rollback.

### Quick resume commands

```bash
waydroid status
hyprctl clients -j | jq -r '.[] | "\(.class) \(.at) \(.size) ws=\(.workspace.id)"'
waydroid show-full-ui          # also unfreezes a frozen container
grim -g "$(hyprctl clients -j | jq -r '.[] | select(.class=="Waydroid") | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" /tmp/wd.png
ffmpeg -loglevel error -i /tmp/wd.png -vf scale=6:3 -f rawvideo -pix_fmt rgb24 - | xxd -p -c 18
```

Expected today: the grid is near-black (`04`/`05`/`06`). After moving the
display to AMD, expect the ATV launcher instead.

### Files changed but uncommitted (2026-10-25)

`AGENTS.md`, `docs/waydroid/{PLAN,README,SPIKE}.md`,
`modules/scripts/waydroid-atv-install.sh` — userdata wipe, prop re-apply, and
this handoff. Commit once the topology decision is made (or commit the
docs/script now — they are independent of the fix).


### Live capture — 2026-10-27 20:19

Current session (`waydroid show-full-ui`): Window `Waydroid` at `[1925,1102]`
size `[943,514]` on workspace 2, mapped but black.

```text
grim -g "$(hyprctl clients -j | jq -r '.[] | select(.class=="Waydroid") | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')" /tmp/wd.png
ffmpeg -loglevel error -i /tmp/wd.png -vf scale=6:3 -f rawvideo -pix_fmt rgb24 - | xxd -p -c 18

030004030004030004030004030004030004
020003020003020003020003020003020003
020002020002020002020002020002020002
```

This matches the cross-GPU A/B test: NVIDIA-rendered content is visible,
Mesa/AMD-rendered content is black on the NVIDIA compositor with no
import errors logged. Same symptom for Waydroid. Confirmed cross-GPU.


### Live capture — 2026-10-27 21:30

**Attempt: software rendering on NVIDIA (same-GPU test)**

Tried forcing software rendering to run on the NVIDIA GPU (`renderD128`) to avoid
cross-GPU dma-buf issues:

1. Edited `/var/lib/waydroid/waydroid_base.prop` (not `waydroid.prop` which gets
   regenerated) with:
```conf
ro.hardware.gralloc=gbm
ro.hardware.egl=swiftshader
gralloc.gbm.device=/dev/dri/renderD128
```
2. Deleted `/var/lib/waydroid/waydroid.prop` to force regeneration
3. Restarted `waydroid-container`

**Result:** Unstable - window opened and closed rapidly in a loop. Container
became unresponsive; had to revert. Logs showed repeated start/stop cycles.

**Lesson:** Proprietary NVIDIA + Waydroid software rendering is problematic on
this setup. The GPU probe in Waydroid 1.6.3 blocks proprietary `nvidia` driver
(`unsupported = ["nvidia"]` in `tools/helpers/gpu.py`), and even with config
overrides the HWC/composer crashes. Same-GPU software rendering is not a
viable fix here.

**Reverted:** Restored `waydroid_base.prop` backup, back to working AMD config
(`gralloc.gbm.device=/dev/dri/renderD129`, `ro.hardware.gralloc=minigbm_gbm_mesa`,
`ro.hardware.egl=mesa`).
