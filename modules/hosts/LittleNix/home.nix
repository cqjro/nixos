{ ... }:
{
	flake.modules.homeManager.LittleNix = {
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

		hyprland = {
			monitors = [
				"eDP-1,2560x1600@60,0x0,1.25"
			];
			bindel = [
				",XF85MonBrightnessUp, exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%+"
				",XF85MonBrightnessDown, exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%-"
				",XF85KbdBrightnessUp, exec, brightnessctl --device :white:kbd_backlight -e4 set 5%+"
				",XF85KbdBrightnessDown, exec, brightnessctl --device :white:kbd_backlight -e4 set 5%-"
			];
		};

		home.sessionPath = [
			"/homes/cairo/.nixos"
		];
	};
}