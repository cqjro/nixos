{pkgs, lib, config, ...}:
{

	options = {
		power-profiles-daemon.enable = lib.mkEnableOption "enable power profiles daemon";
	};

	config = lib.mkIf config.power-profiles-daemon.enable { 
		environment.systemPackages = with pkgs; [
			power-profiles-daemon
		];

		services.power-profiles-daemon = {
			enable = true;
		};
	};
}
