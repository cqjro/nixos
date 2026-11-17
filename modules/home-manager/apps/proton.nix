{ ... }:
{
	# The Proton apps the repo ships, split out of apps-packages so a small host
	# (CHRONOCIDE) can take them without the rest of that bag. Proton Drive has
	# no Linux desktop client in nixpkgs, so there is nothing to add for it.
	flake.modules.homeManager."proton-apps" = { pkgs, ... }: {
		home.packages = with pkgs; [
			protonmail-desktop # email
			proton-vpn-cli # vpn cli
			proton-vpn # vpn gui
			proton-pass # password manager
		];
	};
}
