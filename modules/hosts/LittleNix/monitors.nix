{ ... }:
{
	flake.modules.nixos."LittleNix-monitors" = { pkgs, ... }: {
		environment.systemPackages = with pkgs; [
			brightnessctl
		];
	};

	flake.modules.homeManager."LittleNix-monitors" = {
		hyprland.bindel = [
			",XF86MonBrightnessUp,   exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%+"
			",XF86MonBrightnessDown, exec, brightnessctl --device acpi_video0 -e4 -n2 set 5%-"
			",XF86KbdBrightnessUp,   exec, brightnessctl --device :white:kbd_backlight -e4 set 5%+"
			",XF86KbdBrightnessDown, exec, brightnessctl --device :white:kbd_backlight -e4 set 5%-"
		];
	};
}
