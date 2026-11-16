#!/usr/bin/env bash
# focus-window.sh
# Usage: focus-window.sh [--by class|title|initialTitle] <execCommand> <matchValue> <workspaceOnStart>
# Works under Hyprland (hyprctl) and niri (niri msg); the compositor is told
# apart by the socket variable its session exports.
#   - niri has no `initialTitle` (matched as `title`) and no fixed workspace
#     numbers for a new app (windows open to the right of the focus), so
#     <workspaceOnStart> is ignored there.
BY="class"
if [[ "$1" == "--by" ]]; then
    BY="$2"
    shift 2
fi
execCommand=$1
matchValue=$2
workspaceOnStart=$3

if [[ -n "$NIRI_SOCKET" && -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    # niri: window.app_id is the Wayland counterpart of Hyprland's class
    field="app_id"
    [[ "$BY" != "class" ]] && field="title"
    id=$(niri msg --json windows | jq -r --arg v "$matchValue" ".[] | select(.${field} == \$v) | .id" | head -n 1)
    if [[ -n "$id" ]]; then
        echo "focus"
        niri msg action focus-window --id "$id"
    else
        echo "start"
        ${execCommand} &
    fi
    exit 0
fi

running=$(hyprctl -j clients | jq -r ".[] | select(.${BY} == \"${matchValue}\") | .workspace.id")
echo $running
if [[ $running != "" ]]; then
    echo "focus"
    if [[ "$BY" == "class" ]]; then
        hyprctl dispatch "hl.dsp.focus({ window = 'class:${matchValue}' })"
    else
        hyprctl dispatch "hl.dsp.focus({ workspace = ${running} })"
    fi
else
    echo "start"
    if [[ -n "$workspaceOnStart" ]]; then
        hyprctl dispatch "hl.dsp.focus({ workspace = ${workspaceOnStart} })"
    fi
    ${execCommand} &
fi
