#!/usr/bin/env bash
# focus-window.sh
# Usage: focus-window.sh [--by class|title|initialTitle] <execCommand> <matchValue> <workspaceOnStart>
BY="class"
if [[ "$1" == "--by" ]]; then
    BY="$2"
    shift 2
fi
execCommand=$1
matchValue=$2
workspaceOnStart=$3

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
