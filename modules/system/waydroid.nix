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