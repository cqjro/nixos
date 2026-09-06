{ ... }:
{
	flake.modules.homeManager.GOD-KILLER = {
		home.sessionVariables = {
			EDITOR = "nvim";
			BROWSER = "zen";
			TERMINAL = "ghostty";
			NIXOS_OZONE_WL = "1";
			ELECTRON_OZONE_PLATFORM_HINT = "wayland";
			OZONE_PLATFORM_HINT = "wayland";
			XDG_SESSION_TYPE = "wayland";
			XDG_SESSION_DESKTOP = "Hyprland";
		};

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