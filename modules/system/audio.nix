{ ... }:
{
	flake.modules.nixos.audio = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			easyeffects
		];
	};
}