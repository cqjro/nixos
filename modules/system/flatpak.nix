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