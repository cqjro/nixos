{ ... }:
{
	flake.modules.nixos."REGICIDE-monitors" = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			brightnessctl
		];
	};

	flake.modules.homeManager."REGICIDE-monitors" = {
		hyprland.bindel = [
			",XF86MonBrightnessUp,   exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%+"
			",XF86MonBrightnessDown, exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%-"
			",XF86KbdBrightnessUp,   exec, brightnessctl --device :white:kbd_backlight -e4 set 5%+"
			",XF86KbdBrightnessDown, exec, brightnessctl --device :white:kbd_backlight -e4 set 5%-"
		];

		# niri backup session: the same brightnessctl commands as the Hyprland binds
		niri.brightnessBinds = [
			''XF86MonBrightnessUp allow-when-locked=true { spawn-sh "brightnessctl --device acpi_video0 -e4 -n2 set 5%+"; }''
			''XF86MonBrightnessDown allow-when-locked=true { spawn-sh "brightnessctl --device acpi_video0 -e4 -n2 set 5%-"; }''
			''XF86KbdBrightnessUp allow-when-locked=true { spawn-sh "brightnessctl --device :white:kbd_backlight -e4 set 5%+"; }''
			''XF86KbdBrightnessDown allow-when-locked=true { spawn-sh "brightnessctl --device :white:kbd_backlight -e4 set 5%-"; }''
		];
	};
}
