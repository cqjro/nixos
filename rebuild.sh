#!/usr/bin/env bash

# Inspired by the script from the no boilerplate video

set -e # exists the script if there is any error

# Edit your config
# $EDITOR configuration.nix

# cd to your config dir
pushd ~/.nixos

# Get the list of directories and store them in an array
TARGET_DIR="$HOME/.nixos/hosts"

dir_list=()
while IFS= read -r -d '' dir; do
    dir_list+=("$(basename "$dir")")
done < <(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

PS3="Please select a host: "
select dir in "${dir_list[@]}"; do
    if [[ -n "$dir" ]]; then
        echo "You selected: $dir"
        # You can now use $dir for further processing
        break
    else
        echo "Invalid selection."
    fi
done

# Early return if no changes were detected (thanks @singiamtel!)
if git diff --quiet '*.nix'; then
    echo "No changes detected, exiting."
		popd	
    exit 0
fi

# Autoformat your nix files
# alejandra . &>/dev/null \
#   || ( alejandra . ; echo "formatting failed!" && exit 1)

# Shows your changes
git diff -U0 '*.nix'

echo "About to rebuild NixOS for host: $dir"

# Rebuild, output simplified errors, log trackebacks
sudo nixos-rebuild switch --flake ".#$dir" &>nixos-switch.log || (cat nixos-switch.log | grep --color error && exit 1)

echo "NixOS Rebuilding..."

# Get current generation metadata
current=$(nixos-rebuild list-generations | grep current)

# Commit all changes witih the generation metadata
git add --all
git commit -am "$current"

# Notify all OK!
echo "NixOS Rebuilt OK!"
notify-send -e "NixOS Rebuilt OK!" --icon=software-update-available

#Move back to the orignial directory
popd
