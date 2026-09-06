{ ... }:
{
	flake.modules.homeManager.GOD-KILLER = {
		home.username = "cairo";
		home.homeDirectory = "/home/cairo";

		# This value determines the Home Manager release that your configuration is
		# compatible with. This helps avoid breakage when a new Home Manager release
		# introduces backwards incompatible changes.
		home.stateVersion = "24.11";

		home.file = {};

		# Let Home Manager install and manage itself.
		programs.home-manager.enable = true;

		# get rid of mismatch version error on rebuild
		stylix.enableReleaseChecks = false;

		# configuring pc specific hyprland settings
		hyprland = {
			monitors = [
				"desc:BNQ BenQ EW2780U L6L01871019,3840x2160@60,640x-1440,1.50" # BENQ
				"desc:Microstep MAG321UP OLED,3840x2160@165,0x0,1.00" # MSI OLED
			];
			bindel = [
				",XF86MonBrightnessUp,   exec, ddcutil setvcp 10 + 5 --bus 9 --noverify --sleep-multiplier 0.1 && ddcutil setvcp 10 + 5 --bus 10 --noverify --sleep-multiplier 0.1"
				",XF86MonBrightnessDown, exec, ddcutil setvcp 10 - 5 --bus 9 --noverify --sleep-multiplier 0.1 && ddcutil setvcp 10 - 5 --bus 10 --noverify --sleep-multiplier 0.1"
			];
		};

		home.sessionPath = [
			"/homes/cairo/.nixos"
		];
	};
}