# Waydroid base module (reintegrated from modules/_archive/waydroid.nix for the
# Android TV work — see docs/waydroid/PLAN.md).
{ ... }:
{
	flake.modules.nixos.waydroid = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			waydroid
			waydroid-helper
		];

		virtualisation.waydroid.enable = true;
	};
}
