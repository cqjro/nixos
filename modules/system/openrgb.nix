{lib, pkgs, config, ...}:
{
	options = {
		openrgb.enable = lib.mkEnableOption "enabling openrgb";
	};

	config = lib.mkIF config.opengrgb.enable {
		
		environment.systemPackages = with pkgs; [
			openrgb-with-all-plugins
		];

		# adding this solves the "missing udev rules" issue
		services.hardware.openrgb.enable = true;
	};

}
