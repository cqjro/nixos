{ ... }:
{
	flake.modules.nixos.experimental-features = {
		nix.settings.experimental-features = [ "nix-command" "flakes" ];
	};
}