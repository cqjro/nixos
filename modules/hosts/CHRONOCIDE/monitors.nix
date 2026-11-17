{ ... }:
{
	# Backlight keys. brightnessctl and its udev rules are in machine.nix; the
	# user is in the video group (modules/essentials/users.nix). Device names are
	# the ones the MacBook Air 2015 exposes: check `brightnessctl --list`.
	flake.modules.homeManager."CHRONOCIDE-monitors" = {
		niri.brightnessBinds = [
			''XF86MonBrightnessUp allow-when-locked=true { spawn-sh "brightnessctl --class=backlight -e4 -n2 set 5%+"; }''
			''XF86MonBrightnessDown allow-when-locked=true { spawn-sh "brightnessctl --class=backlight -e4 -n2 set 5%-"; }''
			''XF86KbdBrightnessUp allow-when-locked=true { spawn-sh "brightnessctl --device=smc::kbd_backlight -e4 set 5%+"; }''
			''XF86KbdBrightnessDown allow-when-locked=true { spawn-sh "brightnessctl --device=smc::kbd_backlight -e4 set 5%-"; }''
		];
	};
}
