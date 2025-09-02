# configured using nix-flatpak
{
	services.flatpak = {
		enable = true;
		uninstallUnmanaged = true;
		packages = [
			"app.openbubbles.OpenBubbles"
			"com.github.tchx84.Flatseal"
			"org.vinegarhq.Sober"
			"me.proton.Mail"
		];
	};
}
