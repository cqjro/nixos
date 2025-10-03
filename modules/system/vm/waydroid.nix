{pkgs, config, lib, ...}:
{
	options = {
		waydroid.enable = lib.mkEnableOption "enable waydroid module";
	};

	config = lib.mkIf config.nvidia.enable {
		
		environment.systemPackages = with pkgs; [
			waydroid
			waydroid-helper
		];

		virtualisation.waydroid.enable = true;

	};	

}
