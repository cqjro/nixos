#!/usr/bin/env bash
# keybind-cheatsheet.sh
#
# Omarchy-style "Super+K" live keybind popup. Regenerates on every call,
# straight from your actual live config (no separate doc to keep in sync).
#
# Sources merged:
#   1. Hyprland `bindd` binds  -> read via `hyprctl binds -j` (has native
#      description field, same field Omarchy's own Super+K uses)
#   2. xremap binds            -> read via parse_xremap.py, using the
#      `# comment` sections as descriptions
#
# Usage: bind this to a key in hyprland.conf, e.g.:
#   bindd = SUPER, K, Show keybind cheat sheet, exec, ~/.local/bin/keybind-cheatsheet.sh
#
# Requires: jq, and one of rofi / wofi / fuzzel (edit LAUNCHER below).

set -euo pipefail

XREMAP_NIX="${XREMAP_NIX:-$HOME/.nixos/modules/keyboard/xremap.nix}"
PARSE_SCRIPT="${PARSE_SCRIPT:-$HOME/.nixos/modules/scripts/parse_xremap.py}"
LAUNCHER="${LAUNCHER:-walker}"   # rofi | wofi | fuzzel | walker

# --- 1. Hyprland binds (native description field via bindd) ---
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
        .description
      ]
    | @tsv
  ' 2>/dev/null || true)
fi

# --- 2. xremap binds (comment-derived descriptions) ---
xremap_lines=""
if [[ -f "$XREMAP_NIX" && -f "$PARSE_SCRIPT" ]]; then
  xremap_lines=$(nix shell nixpkgs#python3 -c python3 "$PARSE_SCRIPT" "$XREMAP_NIX" \
    | jq -r '.[] | [.chord, .action] | @tsv')
fi

# --- 3. Merge, format as "Chord \t Description" -> menu rows ---
all_rows=$(printf "%s\n%s\n" "$hypr_lines" "$xremap_lines" | sed '/^$/d' | sort)

menu_text=$(printf "%s\n" "$all_rows" | awk -F'\t' '{printf "%-28s  %s\n", $1, $2}')

case "$LAUNCHER" in
  rofi)
    printf "%s\n" "$menu_text" | rofi -dmenu -i -p "Keybinds" -no-custom \
      -theme-str 'window {width: 900px;} listview {lines: 20; fixed-height: true;} element {orientation: horizontal;} element-text {horizontal-align: 0; expand: true; text-transform: none;}'
    ;;
  wofi)
    printf "%s\n" "$menu_text" | wofi --dmenu -i -p "Keybinds" --width 700 --lines 20
    ;;
  fuzzel)
    printf "%s\n" "$menu_text" | fuzzel --dmenu -p "Keybinds: "
    ;;
  walker)
    printf "%s\n" "$menu_text" | walker --dmenu --placeholder "Keybinds" --width 900
    ;;
  *)
    echo "Unknown LAUNCHER: $LAUNCHER" >&2
    printf "%s\n" "$menu_text"
    ;;
esac
