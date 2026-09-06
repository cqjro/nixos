{ ... }:
{
	flake.modules.nixos.system = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			ddcutil
		];
	};
}