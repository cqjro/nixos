#!/usr/bin/env bash
# Inspired by the script from the noboilerplate video
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
        break
    else
        echo "Invalid selection."
    fi
done
# Early return if no changes were detected (thanks @singiamtel!)
if git diff --quiet; then
    echo "No changes detected, exiting."
		popd	
    exit 0
fi
# Autoformat your nix files
# alejandra . &>/dev/null \
#   || ( alejandra . ; echo "formatting failed!" && exit 1)
# Shows your changes
git diff -U0
read -p "Please provide a commit message: " message
# echo $message
echo "About to rebuild NixOS for host: $dir"
while true; do
    read -p "Do you want to proceed? (y/n) " yn
    case $yn in
        [Yy]* ) echo "Proceeding..."; break;; # User entered 'y' or 'Y'
        [Nn]* ) echo "Exiting..."; exit;;     # User entered 'n' or 'N', script exits
        * ) echo "Invalid response. Please answer y or n.";; # Invalid input, prompt again
    esac
done
echo "NixOS Rebuilding..."
git add --all # to ensure there isnt issues during build

# Determine whether we're rebuilding locally or remotely
current_hostname="$(hostname)"
rebuild_cmd=(sudo nixos-rebuild switch --flake ".#$dir")

if [[ "$current_hostname" != "$dir" ]]; then
    echo "Current hostname ('$current_hostname') differs from selected host ('$dir')."
    read -p "Enter target user: " target_user
    read -p "Enter target IP address: " target_ip
    rebuild_cmd=(sudo nixos-rebuild switch --flake ".#$dir" --target-host "${target_user}@${target_ip}")
fi

# Rebuild, output simplified errors, log trackebacks
"${rebuild_cmd[@]}" &>./.log/nixos-switch.log || (bat ./.log/nixos-switch.log | grep --color error && exit 1)
# Get current generation metadata
if ! current=$(nixos-rebuild list-generations | awk '$NF == "True"'); then
    echo "Failed to get current generation metadata!"
    exit 1
fi
# Commit all changes witih the generation metadata
if ! git commit -m "$dir: $current || $message"; then
    echo "Failed to commit changes!"
    exit 1
fi
#Push to main repo
if ! git push origin master; then
    echo "Failed to push to remote repository!"
    exit 1
fi
# Notify all OK!
echo "NixOS Rebuilt OK!"
notify-send -e "NixOS Rebuilt OK! \n ${current}" --icon=software-update-available
#Move back to the orignial directory
popd
