#!/usr/bin/env bash
# keybind-cheatsheet.sh
#
# Omarchy-style "Super+K" live keybind popup. Regenerates on every call,
# straight from your actual live config (no separate doc to keep in sync).
# Selecting an entry now EXECUTES it (Hyprland dispatch or xremap command),
# same as pressing the real chord would.
#
# Sources merged:
#   1. Hyprland `bindd` binds  -> read via `hyprctl binds -j`
#   2. xremap binds            -> read via parse_xremap.py
#
# Usage: bind this to a key in hyprland.conf, e.g.:
#   bindd = SUPER, K, Show keybind cheat sheet, exec, ~/.nixos/modules/scripts/keybind-cheatsheet.sh
#
# Requires: jq, and one of rofi / wofi / fuzzel / walker (edit LAUNCHER below).

set -euo pipefail

XREMAP_NIX="${XREMAP_NIX:-$HOME/.nixos/modules/keyboard/xremap.nix}"
PARSE_SCRIPT="${PARSE_SCRIPT:-$HOME/.nixos/modules/scripts/parse_xremap.py}"
LAUNCHER="${LAUNCHER:-walker}"   # rofi | wofi | fuzzel | walker

# --- 1. Hyprland binds ---
# 3rd column is "HYPRCTL:<dispatcher> <arg>" so we can replay the exact
# dispatch call hyprctl itself would run for that bind.
hypr_lines=""
if command -v hyprctl >/dev/null 2>&1; then
  hypr_lines=$(hyprctl binds -j | jq -r '
    .[]
    | select(.description != null and .description != "")
    | [
        (
          [ (if .modmask == 0 then empty else .modmask end) ]
          + [ .key ]
          | join("+")
        ),
        .description,
        ("HYPRCTL:" + .dispatcher + " " + .arg)
      ]
    | @tsv
  ' 2>/dev/null || true)
fi

# --- 2. xremap binds ---
# 3rd column is "SHELL:<shell-quoted command>" built from raw_command,
# so it can be eval'd directly exactly as xremap would run it.
xremap_lines=""
if [[ -f "$XREMAP_NIX" && -f "$PARSE_SCRIPT" ]]; then
  xremap_lines=$(nix shell nixpkgs#python3 -c python3 "$PARSE_SCRIPT" "$XREMAP_NIX" \
    | jq -r '.[] | [.chord, .action, ("SHELL:" + (.raw_command | @sh))] | @tsv')
fi

# --- 3. Merge rows, build display text + a lookup table back to the
#        real command, keyed by the exact line the launcher will return ---
all_rows=$(printf "%s\n%s\n" "$hypr_lines" "$xremap_lines" | sed '/^$/d' | sort)

declare -A CMDMAP
menu_lines=()
while IFS=$'\t' read -r chord desc payload; do
  [[ -z "$chord" ]] && continue
  line=$(printf "%-28s  %s" "$chord" "$desc")
  menu_lines+=("$line")
  CMDMAP["$line"]="$payload"
done <<< "$all_rows"

menu_text=$(printf "%s\n" "${menu_lines[@]}")

# --- 4. Show the picker, capture the selection ---
selection=""
case "$LAUNCHER" in
  rofi)
    selection=$(printf "%s\n" "$menu_text" | rofi -dmenu -i -p "Keybinds" -no-custom \
      -theme-str 'window {width: 900px;} listview {lines: 20; fixed-height: true;} element {orientation: horizontal;} element-text {horizontal-align: 0; expand: true; text-transform: none;}')
    ;;
  wofi)
    selection=$(printf "%s\n" "$menu_text" | wofi --dmenu -i -p "Keybinds" --width 700 --lines 20)
    ;;
  fuzzel)
    selection=$(printf "%s\n" "$menu_text" | fuzzel --dmenu -p "Keybinds: ")
    ;;
  walker)
    selection=$(printf "%s\n" "$menu_text" | walker --dmenu --placeholder "Keybinds" --width 900)
    ;;
  *)
    echo "Unknown LAUNCHER: $LAUNCHER" >&2
    exit 1
    ;;
esac

# Escape/empty selection -> just close, nothing to run
[[ -z "$selection" ]] && exit 0

payload="${CMDMAP[$selection]:-}"
if [[ -z "$payload" ]]; then
  echo "No matching action for: $selection" >&2
  command -v notify-send >/dev/null 2>&1 && notify-send "Keybind Cheatsheet" "No action found for that entry"
  exit 1
fi

# --- 5. Execute, backgrounded so the launcher/script doesn't block ---
case "$payload" in
  HYPRCTL:*)
    args="${payload#HYPRCTL:}"
    hyprctl dispatch $args &
    disown
    ;;
  SHELL:*)
    cmd="${payload#SHELL:}"
    eval "$cmd" &
    disown
    ;;
  *)
    echo "Unrecognized payload type: $payload" >&2
    exit 1
    ;;
esac
