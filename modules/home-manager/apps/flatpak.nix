# configured using nix-flatpak
{
	services.flatpak = {
		enable = true;
		uninstallUnmanaged = true;
		packages = [
			"app.openbubbles.OpenBubbles"
		];
	};
}
