{ ... }:
{
	flake.modules.nixos.android = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			android-tools
		];
	};
}