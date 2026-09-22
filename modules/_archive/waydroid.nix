# Archived from modules/system/waydroid.nix
#
# If integrated, this file belongs at modules/system/waydroid.nix (auto-imported
# by import-tree) and enables the Waydroid Android-in-Linux container plus the
# waydroid / waydroid-helper packages system-wide.
#
# To reintegrate:
#   1. Move the file back:  git mv modules/_archive/waydroid.nix modules/system/waydroid.nix
#   2. Add it to the target host in modules/hosts/host.nix:
#        inputs.self.modules.nixos."waydroid"
#   3. Rebuild the host with ./rebuild.sh (or nixos-rebuild switch --flake ".#<HOST>" --impure).
{ ... }:
{
	flake.modules.nixos.waydroid = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			waydroid
			waydroid-helper
		];

		virtualisation.waydroid.enable = true;
	};
}