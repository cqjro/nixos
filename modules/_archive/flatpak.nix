# Archived from modules/system/flatpak.nix
#
# If integrated, this file belongs at modules/system/flatpak.nix (auto-imported
# by import-tree) and configures Flatpak remotes/packages via the nix-flatpak
# module (services.flatpak).
#
# To reintegrate:
#   1. Move the file back:  git mv modules/_archive/flatpak.nix modules/system/flatpak.nix
#   2. Uncomment the nix-flatpak input in flake.nix and re-lock
#      (nix flake update nix-flatpak or nix flake lock).
#   3. Re-add the nix-flatpak input module to each target host in
#      modules/hosts/host.nix (it was removed when this module was archived):
#        inputs.nix-flatpak.nixosModules.nix-flatpak
#   4. Add the fragment to the module list of each target host:
#        inputs.self.modules.nixos."flatpak"
#   5. Rebuild the host with ./rebuild.sh (or nixos-rebuild switch --flake ".#<HOST>").
{ ... }:
{
	# configured using nix-flatpak
	flake.modules.nixos.flatpak = {
		services.flatpak = {
			enable = true;
			uninstallUnmanaged = true;
			packages = [
				"app.openbubbles.OpenBubbles"
				"com.github.tchx84.Flatseal"
			];
		};
	};
}