{ ... }:
{
	# PhotoCraft: an open-source, clean-room reimplementation of Adobe
	# Photoshop in pure Rust (layers, masks, adjustment layers, PSD support).
	# Not in nixpkgs yet, so it is pulled from NUR repo `Skyb0rg007` — see
	# modules/essentials/nur.nix and the README's "Nix User Repository (NUR)"
	# section.
	flake.modules.homeManager."photocraft" = { pkgs, ... }: {
		home.packages = [
			pkgs.nur.repos.Skyb0rg007.photocraft
		];
	};
}
