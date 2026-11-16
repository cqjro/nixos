# CHRONOCIDE

MacBook Air early 2015, 11-inch (`MacBookAir7,1`): Intel i7 (Broadwell), Intel
HD 6000, **4 GB RAM**, 1366x768, Broadcom BCM4360 Wi-Fi, x86_64. The desktop is
[niri](https://github.com/YaLTeR/niri) with the Noctalia shell, no Hyprland.
Memory is the constraint, so every module below was chosen (or left out) with
that in mind. Files: `modules/hosts/CHRONOCIDE/{machine,hardware,home,monitors}.nix`
and the host entry in `modules/hosts/host.nix`.

> **`hardware.nix` is a placeholder.** It evaluates and builds (by-label
> filesystems), but it is not this machine's real hardware scan. Replace its
> body on the MacBook (step 4 of the install order below).

Memory figures are **rough, unmeasured idle estimates** from the usual size of
each program; measure on the machine (`free -h`, `btop`) and cut what you do not
use. Nothing here has run on the real hardware yet.

## What is installed

### System (NixOS fragments)

| Module | Why | Notes |
| --- | --- | --- |
| `zsh`, `nixpkgs`, `time`, `experimental-features`, `environment`, `users`, `dbus`, `config-revision` | the shared base every host has | `users` also gives `uinput`/`input` access for xremap |
| `networking` | NetworkManager; Noctalia's network widget needs it | pulls the openconnect/openvpn plugins and `wifitui` (small) |
| `bluetooth` | Noctalia's Bluetooth widget needs bluez | `powerOnBoot` is on; costs a little battery |
| `power-profiles` | power-profiles-daemon for Noctalia's profile widget | TLP is deliberately not used (it conflicts) |
| `ssh` | ssh-agent and the GUI askpass that `start.sh` uses | small |
| `stylix` | the base16 palette for every themed app | |
| `rss-sources` | the feed list `nom` reads | data only |
| `keyring` | Secret Service for Electron safeStorage (T3 Code, Proton) and `gh`; unlocked at the greeter login | |
| `niri` (new) | `programs.niri`, polkit, portals; session registered at the greeter | see [niri.md](niri.md) |
| `noctalia-greeter` | login screen that starts niri and unlocks the keyring through PAM | its own mini compositor runs **only until login** (see decision below) |
| inline in `machine.nix` | kernel + Wi-Fi, zram, earlyoom, Intel graphics, thermald, upower, fstrim, libinput, `hid_apple fnmode=2`, pipewire (alsa + pulse), lid suspend, XHC1 wake fix, systemd-boot | the brief's options, each checked against the pinned nixpkgs |
| `nixos-hardware` `apple-macbook-air-7` | `mbpfan` (fan control); its `facetimehd` default is switched off | sets no Wi-Fi, graphics or power options |

### User (Home Manager) apps and modules

Approximate idle RAM in parentheses; "closure" means disk only.

| Module | Role | Why it is here | Approx. RAM |
| --- | --- | --- | --- |
| `CHRONOCIDE`, `CHRONOCIDE-monitors` | host values (niri output, touchpad, brightness keys) | | none |
| `environment` | `EDITOR`, `BROWSER=zen`, `TERMINAL=ghostty`, Wayland hints | | none |
| `niri` | generated `config.kdl`, validated at build | the desktop | niri ~60 MB |
| `noctalia-shell` | bar, launcher, lock, idle, wallpaper, clipboard, screenshots, notifications | every `Super+R/A/D/C/S/B/V/M/L` xremap chain drives it with `noctalia msg` | ~100-200 MB (C++ shell; far lighter than the Quickshell build the brief assumed) |
| `gtk`, `xdg-desktop-entries` | icon theme, the Vesktop launcher entry | small | none |
| `keyring` | gnome-keyring user service | | ~10 MB |
| `zsh`, `starship`, `zoxide`, `bat` | shell and prompt | terminal fragments | <30 MB |
| `ghostty` | terminal | **kept** (a lighter terminal such as foot would save ~100 MB, but xremap, `TERMINAL` and the `ghostty -e nvim` window-title matches all assume ghostty, and it needs only OpenGL 3.3, which the HD 6000 has) | ~100-200 MB per window |
| `git`, `nvim`, `yazi`, `btop`, `ncspot`, `nom`, `opencode` | the terminal tools | **heavy on disk**: `nvim` brings rust-analyzer, gopls, pyright and `mermaid-cli` (a bundled Chromium), a few GB of closure on a small SSD | nvim ~100 MB with LSPs, `opencode` ~200 MB while open, the rest <50 MB |
| `terminal-packages` | `jq` (needed by `focus-window.sh`), `fzf`, `eza`, `dust`, `ncdu`, `bluetui`, `wiremix`, `ffmpeg`, `youtube-tui`, ... | all terminal fragments requested | none idle |
| `xremap` | key remaps; `withNiri` here | requested | ~5 MB |
| `zen-browser` | `Super+O Z`; the only browser | `BROWSER=zen` and the xremap launcher | **~700 MB-1.5 GB** with a few tabs; the biggest thing on the machine |
| `nemo` | `Super+O F` file manager | xremap | ~80 MB |
| `discord` (Vesktop only) | `Super+O V` | xremap; the stock Discord client is switched off in `home.nix` | **~400-600 MB** |
| `t3code` | `Super+O T` | xremap launches it | **~500 MB-1 GB** (Electron) and a local rebuild of the app: always build with `--build-host`. Its Hyprland snapshot helper is useless on niri. First thing to drop if memory is tight |
| `proton-apps` (new) | Proton Mail (`Super+O P`), Proton VPN (GUI + CLI), Proton Pass | requested; split out of `apps-packages` so this host does not take the rest of that bag. Proton Drive has no Linux desktop client in nixpkgs, so there is none to include | Mail ~300-500 MB, Pass ~300 MB (both Electron), VPN GUI ~150 MB |
| `obsidian` | `Super+O N` | xremap (installed from `home.nix`) | ~300-500 MB (Electron) |
| `zathura` | PDF viewer | tiny; document viewing without a browser | ~30 MB |
| `wl-clipboard`, `libnotify`, `brightnessctl` | CLI helpers (`notify-send` for `start.sh`, backlight keys) | | none |

Only **one** Electron app should be open at a time on this machine; two plus
Zen will push into zram.

### Deliberately left out

| Module | Why |
| --- | --- |
| Steam, games, `millennium`, `minecraft`, `waydroid`, `bigscreen` (Plasma) | no GPU headroom, no RAM; `Super+O S` has nothing to launch |
| `nvidia`, `openrgb`, `manifest` | other hardware |
| `ios-sideloading`, `tether` | iPhone bridge; not needed on this machine |
| `hyprland` (+ the `hyprland` flake input at runtime), `hypr*` tools in `desktop-packages`, `walker` | niri replaces them; Noctalia has its own launcher; no Hyprland compile or runtime |
| `desktop-packages` | its contents are Hyprland tools or are covered by Noctalia/niri (screenshots, polkit, volume, Bluetooth, audio panels); the few needed helpers are listed above |
| `audio` | its only addition is `easyeffects` (heavy GTK/Qt); pipewire is configured inline |
| `printing` (CUPS), `vpn` (openconnect-sso, gpclient), `doodads`, `tailscale` | no use case yet; add when needed |
| `claude-code`, `claude-code-policy`, `secret-guard`, `agent-notifications`, `mcp-servers`, `github-cli`, `theme-shots`, all `*-web-styling` | agent tooling and site styling live on THEOCIDE/MENTICIDE; web styling is Zen CSS for sites that are not worth the build time here |
| `spicetify`, `discord-theme` host options, `mpv`, `sioyek`, `calibre`, `onlyoffice`, `apps-packages` (vlc, obs, remmina, brave, firefox, chromium, helium, ...) | each is 100 MB to 1 GB of RAM or closure for something Zen/`zathura` already covers |
| `3d-printing`, `latex`, `languages-packages`, `dwsim`, `xodus-nexus`, `learnharness`, `nixdatifier`, `rss-sync` | heavy toolchains or tools for other machines; use `nix shell` for a one-off |

## Decisions that differ from the reference brief

- **Kernel 6.18 LTS, not 6.12.** The brief allowed either; 6.12 reaches end of
  life in December 2026. nixpkgs' `broadcom-sta` carries patches up to 7.2, so
  6.18 is inside what it supports. Never `linuxPackages_latest` on this host.
- **Insecure package allowed by name** (`nixpkgs.config.allowInsecurePredicate`)
  instead of the `permittedInsecurePackages` version string: the string must
  contain the kernel version and the driver's patch level, and deriving it from
  `config.boot.kernelPackages` is an infinite recursion.
- **greetd + noctalia-greeter instead of "no display manager".** It lists niri
  without a `niri-session` command on a TTY, and a TTY login would not unlock
  gnome-keyring (T3 Code, Proton and `gh` store secrets there). Its mini
  compositor exits at login. If you would rather have no greeter at all, set
  `services.greetd.enable = false`, drop the greeter fragment from `host.nix`
  and run `niri-session` from the TTY.
- **`trusted-users`** includes `cairo` so a build host can push the closure
  here (see "Build"). `cairo` already has full `sudo`; remove the line if you
  only ever build on the laptop.
- **mbpfan** (from `nixos-hardware`) is kept: fan control on a passively
  throttled i7 is worth it, and it does not conflict with `thermald`.
- **facetimehd** (webcam) is off. Set `hardware.facetimehd.enable = true` in
  `machine.nix` to try it; it needs unfree blobs and may not build on newer
  kernels.

## Install order

First install needs a wired connection (USB Ethernet) or phone tethering: Wi-Fi
does not exist until the `wl` driver is built into the installed system.

1. **Bootstrap.** Boot the NixOS installer on a USB stick over USB Ethernet or
   tethering. Partition GPT: an EFI System Partition of at least **512 MB**
   (`mkfs.vfat -n BOOT`) and the rest ext4 (`mkfs.ext4 -L nixos`); no swap
   partition (zram is the swap). Mount at `/mnt` and `/mnt/boot`.
2. **Minimal first system.** `nixos-generate-config --root /mnt`, add to the
   generated `configuration.nix`: `nix.settings.experimental-features = [ "nix-command" "flakes" ];`,
   `services.openssh.enable = true;`, `networking.networkmanager.enable = true;`,
   a user `cairo` with `wheel`, `boot.loader.systemd-boot.enable = true;`
   and `boot.loader.efi.canTouchEfiVariables = true;`. `nixos-install`, reboot.
   (Do not try to build this flake inside the installer: 4 GB is not enough.)
3. **Clone** this repo to `~/.nixos` (HTTPS or SSH) on the new system.
4. **Real hardware config.** Run `nixos-generate-config --show-hardware-config`
   and replace the body of `modules/hosts/CHRONOCIDE/hardware.nix` with its
   output (keep the fragment name and the notes in that file's header).
   Confirm the chip: `lspci -nn | grep -i broadcom` should show `14e4:43a0`
   (BCM4360).
5. **Build on THEOCIDE** (`./rebuild.sh build CHRONOCIDE` there fills its store
   and proves the config builds). The 4 GB laptop should never compile
   `t3code`, `xremap-niri` or the Wi-Fi module itself.
6. **Switch from the laptop with a remote builder.** `rebuild.sh` has no
   build-host option (and refuses non-local hosts without `--target`), so use
   `nixos-rebuild` directly, as `cairo`, from `~/.nixos` on `master`:

   ```bash
   nixos-rebuild switch --flake ".#CHRONOCIDE" \
     --build-host cairo@<THEOCIDE-address> --sudo --ask-sudo-password
   ```

   Evaluation still happens on the laptop. If it runs out of memory, skip
   evaluation there: on THEOCIDE build the toplevel, then **pull** it from the
   laptop (this needs no sshd on the laptop, which has none) and activate it
   as root:

   ```bash
   # on THEOCIDE
   nix build --no-link --print-out-paths \
     ".#nixosConfigurations.CHRONOCIDE.config.system.build.toplevel"
   # on CHRONOCIDE, with the printed path
   out=/nix/store/...-nixos-system-CHRONOCIDE-...
   nix copy --from ssh-ng://cairo@<THEOCIDE-address> "$out"
   sudo nix-env -p /nix/var/nix/profiles/system --set "$out"
   sudo "$out/bin/switch-to-configuration" switch
   ```

   Both routes only need SSH **from the laptop to THEOCIDE** and rely on
   `cairo` being a trusted Nix user on CHRONOCIDE (set in `machine.nix`).
   CHRONOCIDE runs no sshd. The first switch must happen over the wired
   connection, with a rescue USB and the console at hand (see Recovery).
   Reboot afterwards.
7. **Later rebuilds** use the same command, from merged `master`
   (`git pull --ff-only` first).

## Verify (checklist from the brief, run on the machine)

- [ ] `uname -r` is a 6.18.x kernel; `lsmod | grep wl` shows the driver; Wi-Fi
      connects through NetworkManager (`nmcli device`). No `b43`, `bcma`, `ssb`
      or `brcmfmac` loaded.
- [ ] `swapon --show` shows only zram; `free -h` idle after login is as low as
      possible (note the number in the PR that follows).
- [ ] `vainfo` reports the `i965` driver (`LIBVA_DRIVER_NAME=i965`).
- [ ] Brightness and keyboard backlight keys work (`brightnessctl --list` shows
      `intel_backlight` and `smc::kbd_backlight`; if the names differ, fix
      `monitors.nix`); the F-keys are plain F1-F12 and `fn` gives media keys.
- [ ] Suspend and resume work from the lid and from Noctalia; the lid does not
      wake it immediately (`cat /proc/acpi/wakeup` shows `XHC1 *disabled`).
- [ ] Bluetooth and audio work; Noctalia's network, battery and power-profile
      widgets show real data; the lock screen appears before sleep.
- [ ] `Super+T, T` opens ghostty; `Super+O` then `Z` / `F` / `V` / `N` / `P` /
      `T` start or focus Zen / Nemo / Vesktop / Obsidian / Proton Mail / T3 Code.
- [ ] `niri msg outputs` shows `eDP-1` at 1366x768 scale 1; tap-to-click and
      natural scroll work.

## Recovery

- The hardware placeholder uses the labels `nixos` and `BOOT`: a mismatch or
  an unreplaced placeholder drops the boot into initrd emergency mode. Do the
  first `switch` only after step 4, and prefer `nixos-rebuild boot` first, reboot,
  and only then `switch`.
- If the systemd-boot entry does not persist on this Apple EFI, boot the
  installer USB and use the GRUB fallback in `machine.nix`.
- A bad generation: pick the previous one in the systemd-boot menu. If the
  greeter or niri fails, switch to another VT (Ctrl+Alt+F2) for a text login.
- No Wi-Fi after a bad `wl` build: boot the previous generation, or use USB
  Ethernet or tethering.

## Known risks

- `broadcom_sta` is unfree and **insecure** (CVE-2019-9501/9502, remote code
  execution by crafted Wi-Fi packets). It is the only Wi-Fi driver for this
  card. Staying on an LTS kernel is the mitigation; a USB Wi-Fi adapter is the
  safe alternative.
- A kernel update can break the module. Do not bump this host to a newer
  kernel series without a build and a wired fallback.
- The 4 GB RAM is shared with a compositor, a shell and Electron apps. Build
  everything big elsewhere; keep one Electron app open at a time.
- Several values are **unverified without the hardware**: the backlight device
  names, the `XHC1` wake fix, `hid_apple fnmode`, suspend behaviour, whether
  the systemd-boot entry persists on this firmware (fallback is in the comment
  in `machine.nix`), and the memory numbers above.
- Remote builds need SSH between the machines and the `trusted-users` entry.
