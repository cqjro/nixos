# niri (shared backup desktop)

[niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland compositor)
is available on every graphical host: `THEOCIDE`, `REGICIDE` and `CHRONOCIDE`
(not the headless `MENTICIDE`). On THEOCIDE and REGICIDE it is a **selectable
backup session** next to Hyprland, which stays the greeter's default; on
CHRONOCIDE it is the only session. The shell is the same Noctalia in both.

Pieces (all in `modules/home-manager/desktop/niri.nix`):

| Fragment | What it does |
| --- | --- |
| `flake.modules.nixos.niri` | `programs.niri` (no Nautilus), polkit, and the portals/keyring the niri module enables; registers the `niri` session so noctalia-greeter lists it |
| `flake.modules.homeManager.niri` | generates `~/.config/niri/config.kdl` from options and runs `niri validate` on it **at build time** (an invalid config fails the host build) |

## Trying it on THEOCIDE / REGICIDE

At the noctalia greeter, pick the **niri** session instead of Hyprland and log
in. Noctalia (systemd user unit), xremap and `start.sh` start in either session.
The greeter default stays `--session hyprland`
(`modules/essentials/noctalia-greeter.nix`, a `mkDefault`).

Per-session switches that already follow the compositor:

- `modules/scripts/focus-window.sh` (the `Super+O` launcher chain) uses
  `niri msg` when `NIRI_SOCKET` is set and `hyprctl` otherwise.
- xremap links against Hyprland by default (`services.xremap.withHypr = mkDefault true`);
  no keymap is per-application, so it works in both sessions. CHRONOCIDE sets
  `withNiri = true` instead.
- Not yet compositor-aware (cosmetic): `XDG_SESSION_DESKTOP` in
  `modules/essentials/environment.nix` still says `Hyprland` in shells started
  in a niri session on THEOCIDE/REGICIDE.

## Options (set per host, like `hyprland.monitors` / `hyprland.bindel`)

| Option | Default | Set in |
| --- | --- | --- |
| `niri.outputs.<name>` (`mode`, `scale`, `position`, `transform`, `variableRefreshRate`) | none | `home.nix` (THEOCIDE's two monitors, REGICIDE's panel, CHRONOCIDE's 1366x768) |
| `niri.brightnessBinds` (raw KDL bind lines; counterpart of `hyprland.bindel`) | none | `monitors.nix` (ddcutil on THEOCIDE, brightnessctl on REGICIDE and CHRONOCIDE) |
| `niri.extraBinds`, `niri.extraConfig` | none | any host, raw KDL |
| `niri.touchpad.{tap,naturalScroll,disableWhileTyping,clickMethod,scrollFactor}` | tap off, natural scroll, dwt, clickfinger, 0.7 (the Hyprland values) | CHRONOCIDE turns tap on |
| `niri.columnWidth` | 0.5 | CHRONOCIDE 1.0 |
| `niri.gaps.{inner,outer}` | 5 / 15 (Hyprland `gaps_in` / `gaps_out`) | CHRONOCIDE 4 / 6 |
| `niri.cornerRadius`, `niri.shadow`, `niri.blur`, `niri.focusRing`, `niri.terminal`, `niri.keyboardLayout`, `niri.cursor.*` | radius 10, shadow on, blur off, ring off, ghostty, us, the Stylix cursor | blur on for THEOCIDE; CHRONOCIDE: shadow off, ring on |

Colours (overview backdrop, insert hint, focus ring) come from Stylix; the
cursor from `stylix.cursor`.

## Hyprland to niri mapping

| Hyprland | niri |
| --- | --- |
| `SUPER+Q` close | `Mod+Q` `close-window` |
| `SUPER+V` float, `SUPER+F` fullscreen | `Mod+V` `toggle-window-floating`, `Mod+F` `fullscreen-window` |
| `SUPER+H/L` focus left/right | `focus-column-left/right` |
| `SUPER+J/K` focus down/up | `focus-window-or-workspace-down/up` |
| `SUPER+1..0`, `SUPER+SHIFT+1..0` | `focus-workspace N`, `move-window-to-workspace N` |
| `SUPER+S` / `SUPER+SHIFT+S` special workspace `magic` | named workspace `magic` (`focus-workspace "magic"`, `move-window-to-workspace "magic"`; a normal workspace, not an overlay) |
| `SUPER+scroll` workspace | `Mod+WheelScroll` `focus-workspace-up/down` |
| `ALT+S`, `ALT+SHIFT+S` grimblast copysave | niri's own `screenshot-screen` / `screenshot` (copies and saves) |
| media keys (`playerctl`) | `noctalia msg media ...`; volume keys added (`noctalia msg volume-*`) |
| brightness keys | per-host `niri.brightnessBinds` |
| window rule: Picture-in-Picture floats | same, bottom-right |
| window rule: `steam_app_*` to `magic` | same |
| autostart `start.sh`, Noctalia, `dbus-update-activation-environment` | `spawn-at-startup start.sh`; Noctalia from its systemd unit; `niri-session` imports the environment |
| `follow_mouse = 1`, touchpad options, rounding 10, gaps, shadow, blur | `focus-follows-mouse`, `input.touchpad`, `geometry-corner-radius`, `gaps` + struts, `shadow`, `background-effect` (niri 26.04) |
| env (`ELECTRON_OZONE_PLATFORM_HINT`, cursor size) | `environment {}` block |
| `hyprland.start` focus special `magic` | none (niri starts on the first workspace) |

**No niri equivalent (left out):**

- `SUPER+M` kill window (niri has only `close-window`).
- `CTRL+SHIFT+2` T3 Code global shortcut (`hl.dsp.global`, a Hyprland protocol).
- `SUPER+ALT+H/J/K/L` PiP corner snapping (`pip-move.sh` uses `hyprctl`; niri
  26.04 has no move-floating-window action: drag with `Mod`+left mouse).
- Window `pin` for the PiP rule.
- `SUPER+mouse` move/resize binds (niri does this natively with `Mod`+drag).
- The per-device mouse sensitivity for `epic-mouse-v1` (niri has no per-device pointer settings).
- The Hyprland `debug.damage_tracking`, `vrr = 0` (niri default is off), and
  per-workspace start numbers for `focus-window.sh` (ignored under niri).
- 3-finger workspace swipe works natively in niri; there is no option for it.

niri-only extras are on keys the xremap chains do not use (`Mod+Return`,
`Mod+Space`, `Alt+Tab`, `Mod+Tab` overview, `Mod+Ctrl+H/J/K/L`, `Mod+,/.`,
`Mod+-/=`, `Mod+Shift+F/C/R/E`, `Mod+Shift+/` hotkey overlay). xremap uses `Super` +
`T/O/M/V/B/R/L/A/D/C/S/K` as chain prefixes in both sessions, so the mapped
binds on those letters (`Mod+V`, `Mod+S`, `Mod+L`) may be intercepted by xremap
exactly as the Hyprland ones are; untested on either.
