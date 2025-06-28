#!/user/bin/env bash

# https://www.reddit.com/r/hyprland/comments/1anmjjy/switch_focus_to_specific_window/
#

execCommand=$1
initialTitle=$2
workspaceOnStart=$3

running=$(hyprctl -j clients | jq -r ".[] | select(.initialTitle == \"${initialTitle}\") | .workspace.id")
echo $running

className=$(hyprctl -j clients | jq -r ".[] | select(.initialTitle == \"${initialTitle}\") | .class")
echo $className

if [[ $running != "" ]]
then
	echo "focus"
	# hyprctl dispatch workspace $running # this works
	hyprctl dispatch workspace $running
else 
	echo "start"
	hyprctl dispatch workspace $workspaceOnStart 
	${execCommand} &
fi
