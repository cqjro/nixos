# Archived from modules/system/android.nix
#
# If integrated, this file belongs at modules/system/android.nix (auto-imported
# by import-tree) and installs android-tools into the system profile.
#
# To reintegrate:
#   1. Move the file back:  git mv modules/_archive/android.nix modules/system/android.nix
#   2. Add it to the target host in modules/hosts/host.nix:
#        inputs.self.modules.nixos."android"
#   3. Rebuild the host with ./rebuild.sh (or nixos-rebuild switch --flake ".#<HOST>").
{ ... }:
{
	flake.modules.nixos.android = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			android-tools
		];
	};
}