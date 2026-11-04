# Gotchas

Hard-won traps, indexed from [AGENTS.md](../../AGENTS.md#gotchas). Add new ones here
and a one-line pointer in the AGENTS.md index.

- **Waydroid Android userdata is `~/.local/share/waydroid`**, not
  `/var/lib/waydroid/userdata.img` (`waydroid.host_data_path`). Replacing the
  images or running `waydroid init -f` does not reset it. Stale data from an
  older Android release makes `zygote`/`system_server` crash-loop after an
  image bump — symptoms: Container RUNNING but IP `UNKNOWN`, `show-full-ui`
  stuck on `waydroidplatform`, and the kernel log repeating
  `process with updatable components 'zygote' exited 4 times before boot
  completed`. Stop the session, `rm -rf ~/.local/share/waydroid`, restart; the
  installer script now does this (`modules/scripts/waydroid-atv-install.sh`).
- **Waydroid is black on GOD-KILLER while the display is on NVIDIA** — confirmed
  2026-10-25, and it is not an image/prop bug. Waydroid's probe skips
  `nvidia`, so it renders on the AMD iGPU (`renderD129`), while Hyprland scans
  out DP-3/HDMI-A-1 from NVIDIA (`card1`); the AMD dmabufs are never presented
  and Hyprland logs no EGL/import error. A forced-Mesa `mpv` reproduces it
  (NVIDIA client visible, AMD client black). Don't chase ATV logcat. See
  `docs/waydroid/PLAN.md` → "Handoff — paused 2026-10-25" for the A/B evidence
  and the topology/upstream options.
- **Xodus Nexus is a pinned AppImage** (`modules/home-manager/apps/xodus-nexus.nix`,
  `GOD-KILLER` only). Nix packages only the launcher; its Xodus backend and
  Nexus runtime self-install from GitHub into the user data directory on first
  run (Settings → Xodus backend / Nexus runtime → Install). The launcher cannot
  self-update from its read-only store path — bump the module's `version` and
  `hash` instead. It needs an unlocked keyring, provided by the shared `keyring`
  fragments (`modules/essentials/keyring.nix`: `gnome-keyring` + greetd PAM
  unlocking; add it to both the host's NixOS list and its `machine.nix`
  imports). T3 Code's desktop app also stores its saved connections there
  ("Desktop secure storage is unavailable" means the keyring is locked). The passkey "Continue in browser"
  fallback needs Google Chrome.
- **Secrets and firmware are gitignored** and must never be committed
  (`client_secret.json`, `token.json`, `config.json`, `firmware/`). The
  YouTube automation needs `token.json` present on the target host. The T2
  Wi-Fi/Bluetooth firmware is proprietary and lives outside the repo (store path
  pinned by hash via `modules/system/t2-firmware.nix`); never read, print or
  attach its contents. See `docs/firmware.md`.
- **YouTube playlist sync is quota-bound** (REDRUM, `modules/server/youtube-automation.nix`
  + `modules/scripts/sync_playlist.py`). The Data API allows 10,000 units/day
  (reads 1, playlist insert/delete 50); polling every subscription's uploads
  playlist every 15 minutes exhausted it on 2026-10-31 (`quotaExceeded` on every
  run, queue stale ~11h; resets midnight Pacific). The script now reads each
  channel's public RSS feed and falls back to a 1-unit `playlistItems.list` only
  for channels whose feed fails; `youtube.com/feeds` is flaky (404/500, sticky
  per channel — some feeds failed 12/12 in testing), so the timer is hourly.
  The script is Nix-managed (store path); only `config.json` / `token.json` are
  hand-placed in `/var/lib/nixos-config/modules/server/youtube/`, and the old
  hand-copied `sync_playlist.py` there is unused. The copy in
  `modules/_archive/youtube-support/` is the retired original — don't edit it.
  Check health with `journalctl -u youtube-playlist-sync` and the quota graph
  in Google Cloud Console (YouTube Data API v3 → Quotas).
- **REDRUM is built from pinned nixpkgs** (`nixpkgs-redrum`, rev `cac0c1ef`)
  because `linux >= 6.18.47` breaks the t2linux patchset. Do not "fix" this
  without reading `modules/hosts/REDRUM/T2-PIN.md` and re-checking
  `NixOS/nixos-hardware#2027` (row 1 of [the registry](upstream-registry.md)). Packages that must
  track upstream security fixes are overridden explicitly —
  currently `services.cloudflared.package` in `modules/server/cloudflared.nix`
  pins Cloudflare's release binary (bump `version` + `hash` there) and
  `services.tailscale.package` in `modules/server/tailscale.nix` pins 1.104.4,
  built from the main `nixpkgs` input's recipe because the pinned rev's Go is
  too old for it (bump `version` + both hashes there); drop such overrides with
  the pin, or as soon as a `nixpkgs` bump covers them.
- **Do not add a `nix flake check` step** back into `rebuild.sh` — the live
  rebuild feed is intentionally streamed through `bat` and only errors are shown
  on failure (see the `PIPESTATUS` handling).
- `system.stateVersion` differs per host — leave it alone unless you know what
  you're doing.
- **The `rebuild` zsh alias runs a copy of `rebuild.sh` in the Nix store**
  (`bash ${../../../rebuild.sh}`), frozen at the last rebuild. After editing the
  script, run `./rebuild.sh` from `~/.nixos` (or rebuild once) — agents must
  always use `./rebuild.sh`, never the alias.
- Flakes only see **tracked** files, so `rebuild.sh build`/`switch` stage with
  `git add --all` first (same as the interactive flow) — new modules are
  invisible to `nixos-rebuild` until staged.
- `stylix.enableReleaseChecks = false` is set in host `home.nix` files to avoid
  the release-mismatch error — keep it consistent across hosts.
- **REDRUM does not import `essentials/users.nix`** — it defines its own
  `users.users.cairo` in `hosts/REDRUM/machine.nix`, so anything the shared
  users module sets (currently `shell = pkgs.zsh`) must be duplicated there.
  Without `shell = pkgs.zsh`, SSH sessions land in bash and none of the
  home-manager zsh config (aliases `rebuild`/`config-sync`/`cd = "z"`, zoxide
  integration) loads. **Do not "fix" this by importing the shared module on
  REDRUM**: it sets `extraGroups = [ … "seat" … "plugdev" ]` and those groups
  are not created by any module REDRUM imports (they exist on the desktop
  hosts only), so user activation fails with `group does not exist` and the
  switch aborts — and it would also enable `hardware.uinput` + the uinput/input
  groups for xremap, which a headless server never uses. When changing
  `essentials/users.nix`, mirror the change in REDRUM's user block.
- **pnpm `packageManager` pins in server FODs** — pnpm's
  `manage-package-manager-versions` self-downloads whatever version
  `package.json` pins whenever it differs from the running `pkgs.pnpm`; that
  fetch fails inside the build sandbox (`Failed to switch pnpm to vX … ENOENT`)
  and silently makes a "fixed-output" derivation depend on a second registry
  download of a pnpm binary. This broke the abt-sidecar deps FOD on
  2026-10-20; the fix (strip `packageManager` with the node one-liner before
  the first pnpm command, re-fetch the FOD hash) is in
  `modules/server/actual-budget-tweaks.nix`. `modules/server/reactflux.nix` is
  currently safe only because its pin (`pnpm@11.21.0`) equals the pinned
  nixpkgs' `pkgs.pnpm` — when bumping either pnpm project, or when the T2 pin
  is lifted (T2-PIN.md step 3), apply the same strip and re-fetch the hash.
- **Server pnpm FOD hashes are not reproducible** — a separate, related trap:
  both `pnpmDeps` fixed-output derivations (`actual-budget-tweaks.nix`,
  `reactflux.nix`) re-resolve **floating dep ranges** from the live npm registry
  on every fetch, so their store+metadata-cache output — and therefore
  `outputHash` — drifts over time and across the GOD-KILLER/REDRUM pins. Symptom
  is `error: hash mismatch in fixed-output derivation` on an otherwise-unchanged
  tree (observed 2026-10-20 on both FODs in one session). Immediate fix: build
  once, copy the `got:` value into `outputHash`, rebuild. Both sites carry a
  `FIXME:` block. Durable fix: replace the hand-rolled FODs with a
  lockfile-frozen fetch (`fetchPnpmDeps` / `pnpm.fetchDeps`) when the pinned
  nixpkgs ships one that works with these lockfiles.

- **Waydroid software rendering on proprietary NVIDIA is not viable** — Waydroid
  1.6.3's GPU probe hard-blocks the proprietary `nvidia` driver (`unsupported =
  ["nvidia"]` in `tools/helpers/gpu.py`). Forcing software rendering on
  `renderD128` caused the HWC/composer to crash-loop (window opens/closes
  rapidly). Same-GPU software rendering does not bypass this.

- **`rebuild.sh` output and plain-command exclusions** — `rebuild.sh` streams
  to the screen only when stdout is a terminal. Piped (`| tail`) or in an agent
  shell, the output goes to `.log/nixos-<action>.log` (e.g.
  `nixos-dry-activate.log`) and the screen shows only the header line; read that
  file instead. Likewise `gh`, `git push` and `./rebuild.sh` leave the sandbox
  only as plain commands (`sandbox.excludedCommands`): chained with `&&`/`;`,
  piped or with a long inline `--body`, they run sandboxed and `gh` fails with
  "run gh auth login". Use `--body-file` for PR bodies.

- **Sandbox placeholders in `git status`** — inside a sandboxed worktree,
  `/dev/null` placeholder files (`.zshrc`, `.mcp.json`, `.claude/settings.json`,
  …) show as untracked and `.git/config.lock` exists, so `git checkout -b` fails
  on writing the upstream setting. Use `--no-track` and stage by path, never
  `git add --all`. They exist only in the sandbox view.

- **`gh auth status` output trips the secret-guard** — the masked
  `Token: github_pat_****…` line matches the weak "credential assignment"
  pattern and the prompt is blocked before the model sees it. Start the message
  with `[allow-secret-pattern]` (square brackets included); a real full token is
  a strong match and is never bypassed.
