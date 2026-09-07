{ ... }:
{
	flake.modules.nixos.openrgb = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			openrgb-with-all-plugins
		];

		# adding this solves the "missing udev rules" issue
		services.hardware.openrgb = {
			enable = true;
			motherboard = "amd";
		};
	};
}