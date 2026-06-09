#!/usr/bin/env bash
# focus-window.sh
# Usage: focus-window.sh [--by class|title|initialTitle] <execCommand> <matchValue> <workspaceOnStart>
#
# https://www.reddit.com/r/hyprland/comments/1anmjjy/switch_focus_to_specific_window/

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
        hyprctl dispatch focuswindow class:$matchValue
    else
        hyprctl dispatch workspace $running
    fi
else
    echo "start"
    hyprctl dispatch workspace $workspaceOnStart
    ${execCommand} &
fi
