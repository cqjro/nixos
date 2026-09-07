{ ... }:
{
	flake.modules.nixos.nixpkgs = {
		nixpkgs.config.allowUnfree = true;
		nixpkgs.config.allowUnfreePredicate = _: true; # needed for home-manager
	};
}