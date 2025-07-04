#!/user/bin/env bash

# https://www.reddit.com/r/hyprland/comments/1anmjjy/switch_focus_to_specific_window/
#

execCommand=$1
className=$2
workspaceOnStart=$3

running=$(hyprctl -j clients | jq -r ".[] | select(.class == \"${className}\") | .workspace.id")
echo $running

if [[ $running != "" ]]
then
	echo "focus"
	# hyprctl dispatch workspace $running # this works
	hyprctl dispatch focuswindow class:$className
else 
	echo "start"
	hyprctl dispatch workspace $workspaceOnStart 
	${execCommand} &
fi
